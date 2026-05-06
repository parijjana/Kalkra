# QR Secure Handshake - Agent Usage Guide

This SDK provides a zero-friction, high-security handshake protocol for local multiplayer games. It uses QR codes as a secure out-of-band channel to exchange encryption keys.

## Core Concepts

1.  **HandshakeManager**: The primary controller. It generates a 256-bit secret.
2.  **Secret Embedding**: The secret is passed as a query parameter in a standard URI.
3.  **End-to-End Encryption**: Once the secret is shared, all payloads can be encrypted using AES-256.

## Workflow for Agents

### 1. Host Initialization
When implementing a host, generate the manager and embed the secret into the QR data.

```dart
final manager = HandshakeManager.generate();
final qrData = manager.buildUri("ws://192.168.1.5:8080");
// Display qrData in your UI
```

### 2. Host Validation
When a client connects, extract their provided secret (usually from their first 'join' message) and validate it.

```dart
bool authorized = manager.isValid(incomingSecret);
if (!authorized) socket.close();
```

### 3. Client Handshake
When a client scans the QR code, parse the URI to extract the secret.

```dart
final uri = Uri.parse(scannedQrData);
final secret = uri.queryParameters['secret'];
// Use this secret in your connection handshake
```

### 4. Encrypted Communication
Use the manager to encrypt outgoing and decrypt incoming messages.

```dart
String encrypted = manager.encrypt(jsonEncode(myEvent));
socket.send(encrypted);
```

## Security Best Practices
- Never log the `secret` or display it in plain text.
- Regeneration: Create a new `HandshakeManager` every time a new lobby is opened.
- Failure Handling: If `decrypt` throws an exception, immediately terminate the connection as it indicates an invalid key or tampered packet.
