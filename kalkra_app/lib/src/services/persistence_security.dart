import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class PersistenceSecurity {
  /// Internal secret salt for key derivation.
  /// In a production scenario, this should be obfuscated.
  static const String _internalSalt = "KALKRA_VAULT_S01_2026";

  /// Derives a 32-byte (256-bit) key from a hardware-linked seed.
  static Key deriveKey(String deviceId) {
    final bytes = utf8.encode(deviceId + _internalSalt);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts a JSON string and appends an HMAC signature to prevent tampering.
  /// Format: "iv:ciphertext:hmac"
  static String pack(String plainText, String deviceId) {
    final key = deriveKey(deviceId);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    // 1. Encrypt
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final payload = '${iv.base64}:${encrypted.base64}';

    // 2. Sign (HMAC)
    final hmacKey = utf8.encode(_internalSalt + deviceId);
    final hmac = Hmac(sha256, hmacKey);
    final signature = hmac.convert(utf8.encode(payload));

    return '$payload:${signature.toString()}';
  }

  /// Verifies the signature and decrypts the payload.
  /// Throws an exception if tampering is detected.
  static String unpack(String packedData, String deviceId) {
    final parts = packedData.split(':');
    if (parts.length != 3)
      throw Exception('Vault Integrity Error: Invalid Format');

    final payload = '${parts[0]}:${parts[1]}';
    final providedSignature = parts[2];

    // 1. Verify Signature
    final hmacKey = utf8.encode(_internalSalt + deviceId);
    final hmac = Hmac(sha256, hmacKey);
    final expectedSignature = hmac.convert(utf8.encode(payload)).toString();

    if (providedSignature != expectedSignature) {
      throw Exception(
        'Vault Integrity Error: Data has been tampered with or moved.',
      );
    }

    // 2. Decrypt
    final key = deriveKey(deviceId);
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}
