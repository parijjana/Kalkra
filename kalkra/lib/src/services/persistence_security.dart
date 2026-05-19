import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PersistenceSecurity {
  static const String _internalSalt = "KALKRA_VAULT_S01_2026";
  static const String _masterKeyAlias = 'kalkra_master_key_v1';
  static const _storage = FlutterSecureStorage();

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

  /// Encrypts a JSON string and appends an HMAC signature to prevent tampering.
  /// Uses hardware-backed AES keys.
  static Future<String> pack(String plainText, String deviceId) async {
    final key = await _getMasterKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    // 1. Encrypt
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final payload = '${iv.base64}:${encrypted.base64}';

    // 2. Sign (HMAC)
    // We sign with the master key as well to ensure the signature can't be forged 
    // even if the user knows the deviceId and salt.
    final hmacKey = key.bytes; 
    final hmac = Hmac(sha256, hmacKey);
    final signature = hmac.convert(utf8.encode(payload));

    return '$payload:${signature.toString()}';
  }

  /// Verifies the signature and decrypts the payload.
  /// Supports migration from legacy deviceId-derived keys.
  static Future<String> unpack(String packedData, String deviceId) async {
    final parts = packedData.split(':');
    if (parts.length != 3) {
      throw Exception('Vault Integrity Error: Invalid Format');
    }

    final payload = '${parts[0]}:${parts[1]}';
    final providedSignature = parts[2];

    final key = await _getMasterKey();
    
    // 1. Try modern hardware-backed verification
    final hmac = Hmac(sha256, key.bytes);
    final expectedSignature = hmac.convert(utf8.encode(payload)).toString();

    if (providedSignature == expectedSignature) {
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    }

    // 2. Fallback to Legacy verification
    final legacyHmacKey = utf8.encode(_internalSalt + deviceId);
    final legacyHmac = Hmac(sha256, legacyHmacKey);
    final expectedLegacySignature = legacyHmac.convert(utf8.encode(payload)).toString();

    if (providedSignature == expectedLegacySignature) {
      final legacyKey = _deriveLegacyKey(deviceId);
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(legacyKey, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    }

    throw Exception('Vault Integrity Error: Data has been tampered with or moved.');
  }
}
