import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kalkra/src/services/persistence_security.dart';

const _masterKeyAlias = 'kalkra_master_key_v1';
const _internalSalt = 'KALKRA_VAULT_S01_2026';

/// Replicates the OLD AES-CBC "iv:cipher:hmac" pack() logic (master-key
/// backed variant) so we can construct a pre-migration payload in tests.
String _packOldModernFormat(String plainText, Key key) {
  final iv = IV.fromSecureRandom(16);
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  final encrypted = encrypter.encrypt(plainText, iv: iv);
  final payload = '${iv.base64}:${encrypted.base64}';

  final hmac = Hmac(sha256, key.bytes);
  final signature = hmac.convert(utf8.encode(payload));
  return '$payload:${signature.toString()}';
}

/// Replicates the OLD legacy deviceId-derived AES-CBC pack() logic.
String _packOldLegacyFormat(String plainText, String deviceId) {
  final legacyKeyBytes = sha256.convert(utf8.encode(deviceId + _internalSalt));
  final legacyKey = Key(Uint8List.fromList(legacyKeyBytes.bytes));

  final iv = IV.fromSecureRandom(16);
  final encrypter = Encrypter(AES(legacyKey, mode: AESMode.cbc));
  final encrypted = encrypter.encrypt(plainText, iv: iv);
  final payload = '${iv.base64}:${encrypted.base64}';

  final legacyHmacKey = utf8.encode(_internalSalt + deviceId);
  final legacyHmac = Hmac(sha256, legacyHmacKey);
  final signature = legacyHmac.convert(utf8.encode(payload));
  return '$payload:${signature.toString()}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersistenceSecurity', () {
    const deviceId = 'test-device-id';

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      PersistenceSecurity.storage = const FlutterSecureStorage();
    });

    test('pack() produces the v2 plaintext+HMAC format', () async {
      final packed = await PersistenceSecurity.pack('{"hello":"world"}', deviceId);
      final parts = packed.split(':');

      expect(parts.length, 3);
      expect(parts[0], 'v2');
      // Payload must be plaintext (base64), not AES cipher text.
      expect(utf8.decode(base64.decode(parts[1])), '{"hello":"world"}');
    });

    test('round-trips pack() -> unpack() in v2 format', () async {
      const original = '{"playerName":"Fable","elo":1500}';
      final packed = await PersistenceSecurity.pack(original, deviceId);
      final unpacked = await PersistenceSecurity.unpack(packed, deviceId);

      expect(unpacked, original);
    });

    test(
      'unpack() still returns plaintext for v2 data with a bad signature',
      () async {
        const original = '{"playerName":"Tampered"}';
        final packed = await PersistenceSecurity.pack(original, deviceId);
        final parts = packed.split(':');
        final tampered = '${parts[0]}:${parts[1]}:deadbeefdeadbeef';

        final unpacked = await PersistenceSecurity.unpack(tampered, deviceId);
        expect(unpacked, original);
      },
    );

    test(
      'unpack() still returns plaintext for v2 data when the master key is missing',
      () async {
        const original = '{"playerName":"NoKey"}';
        final packed = await PersistenceSecurity.pack(original, deviceId);

        // Simulate the keychain entry vanishing.
        FlutterSecureStorage.setMockInitialValues({});
        PersistenceSecurity.storage = const FlutterSecureStorage();

        final unpacked = await PersistenceSecurity.unpack(packed, deviceId);
        expect(unpacked, original);
      },
    );

    test(
      'unpack() throws for structurally malformed v2 payload',
      () async {
        expect(
          () => PersistenceSecurity.unpack('v2:not-valid-base64!!!:abcd', deviceId),
          throwsException,
        );
      },
    );

    test('migrates old modern (master-key AES) format', () async {
      const original = '{"playerName":"OldModern","elo":1400}';

      // Seed the same master key PersistenceSecurity would use, then build
      // a payload the way the OLD pack() implementation did.
      final key = Key.fromSecureRandom(32);
      FlutterSecureStorage.setMockInitialValues({_masterKeyAlias: key.base64});
      PersistenceSecurity.storage = const FlutterSecureStorage();

      final oldPacked = _packOldModernFormat(original, key);
      final unpacked = await PersistenceSecurity.unpack(oldPacked, deviceId);

      expect(unpacked, original);
    });

    test('migrates old legacy (deviceId-derived AES) format', () async {
      const original = '{"playerName":"OldLegacy","elo":1100}';

      // No master key present -- forces fallback to the legacy path, and
      // the legacy scheme never depended on the keychain anyway.
      FlutterSecureStorage.setMockInitialValues({});
      PersistenceSecurity.storage = const FlutterSecureStorage();

      final oldPacked = _packOldLegacyFormat(original, deviceId);
      final unpacked = await PersistenceSecurity.unpack(oldPacked, deviceId);

      expect(unpacked, original);
    });

    test(
      'throws UnrecoverableVaultException for old-format data that cannot be verified',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        PersistenceSecurity.storage = const FlutterSecureStorage();

        expect(
          () => PersistenceSecurity.unpack(
            'someivbase64==:someciphertextbase64==:notarealhmac',
            deviceId,
          ),
          throwsA(isA<UnrecoverableVaultException>()),
        );
      },
    );
  });
}
