import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';

/// Manages secure handshakes by generating secrets and validating client credentials.
class HandshakeManager {
  final String _secret;

  /// Private constructor.
  HandshakeManager._(this._secret);

  /// Initializes a manager from an existing secret (e.g. scanned from a QR code).
  factory HandshakeManager.fromSecret(String secret) {
    return HandshakeManager._(secret);
  }

  /// Generates a new secure manager with a 256-bit random secret.
  factory HandshakeManager.generate() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return HandshakeManager._(base64Url.encode(values));
  }

  /// The raw Base64 secret key. Embed this in your QR code.
  String get secret => _secret;

  /// Builds a connection URI string with the secret appended as a query parameter.
  /// Example: ws://192.168.1.5:8080?secret=...
  String buildUri(String baseUri) {
    final uri = Uri.parse(baseUri);
    final params = Map<String, String>.from(uri.queryParameters);
    params['secret'] = _secret;
    return uri.replace(queryParameters: params).toString();
  }

  /// Validates if the provided [clientSecret] matches the session secret.
  bool isValid(String? clientSecret) {
    return clientSecret != null && clientSecret == _secret;
  }

  /// Encrypts a [plainText] message using the session secret.
  /// Returns a format: "iv:ciphertext"
  String encrypt(String plainText) {
    final key = Key.fromBase64(_secret);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts an [encryptedPayload] using the session secret.
  String decrypt(String encryptedPayload) {
    final parts = encryptedPayload.split(':');
    if (parts.length != 2) throw Exception('Invalid payload format');
    
    final key = Key.fromBase64(_secret);
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final encrypter = Encrypter(AES(key));
    
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
