import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';

class CryptoUtil {
  /// Generates a random 32-byte key encoded as a Base64 string.
  static String generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Encrypts a plaintext message using AES-256 (CBC mode for wide compatibility).
  /// Returns a colon-separated string: "iv:ciphertext"
  static String encryptMessage(String plainText, String base64Key) {
    try {
      final key = Key.fromBase64(base64Key);
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts a message using the shared Base64 key.
  static String decryptMessage(String encryptedPayload, String base64Key) {
    try {
      final parts = encryptedPayload.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted payload format');

      final key = Key.fromBase64(base64Key);
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}
