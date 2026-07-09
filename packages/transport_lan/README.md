# transport_lan

`transport_lan` is Kalkra's local-network multiplayer transport. It implements the shared `transport_interface` contracts with a host WebSocket server, client WebSocket connections, NSD service registration, encrypted messages, heartbeats, rate limiting, and host controls.

## Components

- `LanHostTransport` - starts a WebSocket server, registers `_kalkra._tcp` with NSD, generates the lobby secret, broadcasts events, accepts client joins, sends heartbeats, and can kick clients.
- `LanClientTransport` - connects to a host URL, extracts the lobby secret from the query string, sends a `playerJoined` event, decrypts host events, and reports heartbeat loss.
- `CryptoUtil` - generates a random 32-byte session key and encrypts/decrypts payloads with AES.

## Basic Flow

Host:

```dart
final host = LanHostTransport();
await host.hostSession(
  playerName: 'Host',
  options: {'port': 0, 'elo': 1200},
);

final secret = host.lobbySecret;
final url = 'ws://HOST_IP:${host.port}?secret=$secret';
```

Client:

```dart
final client = LanClientTransport();
await client.joinSession(
  playerName: 'Player',
  connectionInfo: 'ws://HOST_IP:PORT?secret=LOBBY_SECRET',
  options: {'elo': 1200, 'deviceId': 'stable-device-id'},
);
```

In the app, the connection URL is expected to be carried by the join workflow, commonly as a QR-code payload.

## Security Notes

- The lobby secret is generated per hosted session and is required to decrypt or send accepted messages.
- Payloads are encrypted before being written to the WebSocket.
- The host applies token-bucket rate limiting and drops excessive packets.
- Client-originated events include increasing sequence numbers; the host rejects repeated or older sequence numbers after a client ID is known.
- Hosts can reject banned device IDs and kick connected players.
- Clients report connection loss if host heartbeats stop.

This package is intended for trusted LAN play. Do not expose the host WebSocket port to the public internet, and do not treat the lobby secret as a long-lived credential.

## Testing

```powershell
flutter pub get
flutter analyze
flutter test
```

Tests mock the NSD method channel and exercise host/client connection behavior.

## Caveat

`LanClientTransport` currently requires `connectionInfo` to include `?secret=...`. Some older tests/docs may still show a bare `ws://host:port` URL; the secret-bearing URL is the accurate workflow for the current client code.
