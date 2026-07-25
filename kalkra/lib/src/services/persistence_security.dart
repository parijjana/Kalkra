import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thrown when packed save data matches a known *encrypted* legacy format
/// but can neither be verified nor decrypted (e.g. the hardware-backed
/// master key was lost or rotated). Unlike a signature mismatch on the
/// current plaintext format, this is genuinely unrecoverable -- callers may
/// choose to offer the player a fresh start.
class UnrecoverableVaultException implements Exception {
  final String message;
  const UnrecoverableVaultException(this.message);

  @override
  String toString() => 'UnrecoverableVaultException: $message';
}

class PersistenceSecurity {
  static const String _internalSalt = "KALKRA_VAULT_S01_2026";
  static const String _masterKeyAlias = 'kalkra_master_key_v1';

  /// Marker prefix for the current plaintext + HMAC format, distinguishing
  /// it from the old 3-part "iv:cipher:hmac" AES formats.
  static const String _v2Marker = 'v2';

  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Allows tests to inject a stubbed/fake [FlutterSecureStorage].
  @visibleForTesting
  static set storage(FlutterSecureStorage storage) => _storage = storage;

  /// Retrieves the hardware-backed master key or generates a new one.
  static Future<Key> _getMasterKey() async {
    String? base64Key = await _storage.read(key: _masterKeyAlias);

    if (base64Key == null) {
      // Generate a new random 32-byte key
      final key = Key.fromSecureRandom(32);
      await _storage.write(key: _masterKeyAlias, value: key.base64);
      return key;
    }

    return Key.fromBase64(base64Key);
  }

  /// Legacy: Derives a 32-byte key from hardware deviceId (software-level only).
  static Key _deriveLegacyKey(String deviceId) {
    final bytes = utf8.encode(deviceId + _internalSalt);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }

  /// Packs a JSON string as base64-encoded plaintext with an HMAC signature
  /// appended to detect tampering.
  ///
  /// This format is intentionally NOT encrypted: save data is not secret,
  /// and encrypting it created a real risk of permanently destroying a
  /// player's progress if the platform keystore key was ever lost or
  /// rotated. The HMAC (over the base64 payload) still lets [unpack] detect
  /// tampering and re-sign on the next save.
  ///
  /// Produces `"v2:<base64(utf8(plainText))>:<hmac-hex>"`.
  static Future<String> pack(String plainText, String deviceId) async {
    final key = await _getMasterKey();
    final payload = base64.encode(utf8.encode(plainText));

    final hmac = Hmac(sha256, key.bytes);
    final signature = hmac.convert(utf8.encode(payload));

    return '$_v2Marker:$payload:${signature.toString()}';
  }

  /// Decodes packed save data, transparently migrating older formats.
  ///
  /// Resolution order:
  /// 1. Current `v2` plaintext+HMAC format: the payload is decoded and
  ///    returned regardless of whether the signature verifies -- a bad or
  ///    unverifiable signature never destroys data here, it just means the
  ///    next [pack] call will re-sign it. Only a structurally malformed
  ///    payload (invalid base64/UTF-8) throws.
  /// 2. Old modern format (AES-CBC with the hardware-backed master key).
  /// 3. Old legacy format (AES-CBC with a deviceId-derived key).
  /// 4. If the data has the old 3-part encrypted shape but neither AES path
  ///    can verify/decrypt it (e.g. the master key is gone), throws
  ///    [UnrecoverableVaultException].
  static Future<String> unpack(String packedData, String deviceId) async {
    final parts = packedData.split(':');

    if (parts.length == 3 && parts[0] == _v2Marker) {
      return _unpackV2(parts[1], parts[2]);
    }

    if (parts.length == 3) {
      return _unpackLegacyEncrypted(parts, deviceId);
    }

    throw Exception('Vault Integrity Error: Invalid Format');
  }

  /// Decodes the current plaintext + HMAC format. The signature is
  /// deliberately NOT enforced here: whether it verifies, fails to verify,
  /// or the master key can't be read at all, the decoded plaintext is
  /// always returned -- the caller's next [pack] call re-signs it. Only a
  /// payload that isn't valid base64/UTF-8 throws, since that indicates
  /// genuine data corruption rather than a signature/key problem.
  static Future<String> _unpackV2(
    String payload,
    String providedSignature,
  ) async {
    try {
      return utf8.decode(base64.decode(payload));
    } catch (_) {
      throw Exception('Vault Integrity Error: Malformed Payload');
    }
  }

  /// Handles the old 3-part "iv:cipher:hmac" AES formats: first the modern
  /// hardware-key-backed scheme, then the legacy deviceId-derived scheme.
  static Future<String> _unpackLegacyEncrypted(
    List<String> parts,
    String deviceId,
  ) async {
    final payload = '${parts[0]}:${parts[1]}';
    final providedSignature = parts[2];

    // 1. Try modern hardware-backed verification
    try {
      final key = await _getMasterKey();
      final hmac = Hmac(sha256, key.bytes);
      final expectedSignature = hmac.convert(utf8.encode(payload)).toString();

      if (providedSignature == expectedSignature) {
        final iv = IV.fromBase64(parts[0]);
        final encrypted = Encrypted.fromBase64(parts[1]);
        final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
        return encrypter.decrypt(encrypted, iv: iv);
      }
    } catch (_) {
      // Master key unreadable/corrupt -- fall through to the legacy check.
    }

    // 2. Fallback to legacy deviceId-derived verification
    final legacyHmacKey = utf8.encode(_internalSalt + deviceId);
    final legacyHmac = Hmac(sha256, legacyHmacKey);
    final expectedLegacySignature =
        legacyHmac.convert(utf8.encode(payload)).toString();

    if (providedSignature == expectedLegacySignature) {
      final legacyKey = _deriveLegacyKey(deviceId);
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(legacyKey, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    }

    throw UnrecoverableVaultException(
      'Vault Integrity Error: Data has been tampered with or moved.',
    );
  }
}
