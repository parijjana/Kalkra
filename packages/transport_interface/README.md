# transport_interface

`transport_interface` defines the multiplayer transport contract used by Kalkra. It lets the app and game flow depend on shared event models instead of a specific network implementation.

## Exports

`lib/transport_interface.dart` exports:

- `IGameTransport` - interface for hosting, joining, sending events, kicking players, disconnecting, and reading the event stream.
- `GameEvent` and `GameEventType` - typed event envelope for lobby, round, submission, heartbeat, error, and match lifecycle messages.
- `PlayerInfo` - player metadata used by lobbies and matches.
- `NullTransport` - test/local no-op transport.

## Event Model

Current event types include player join/leave/ready, lobby updates, team assignment/rename, host match start, round start/end/results, submission received, match results/end, kick, heartbeat, and error.

`GameEvent.sequenceNumber` is available for transport-level replay protection. Concrete transports decide how strictly to enforce it.

## Implementing a Transport

An implementation should:

- Provide a stable `myId` for the local participant.
- Emit all inbound messages through `eventStream`.
- Use `hostSession` only for host-capable transports and `joinSession` only for client-capable transports, throwing `UnsupportedError` where not applicable.
- Preserve the `GameEvent` payload shape so app and engine code do not need transport-specific branches.
- Clean up sockets, timers, service discovery registrations, and streams in `disconnect`.

## Testing

```powershell
dart pub get
dart analyze
dart test
```

Tests cover event/model serialization and null transport behavior.
