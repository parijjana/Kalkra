# Kalkra

Kalkra is a Flutter math game built around Gameshow-style arithmetic rounds: players use a small pool of numbers and the operators `+`, `-`, `*`, and `/` to reach a target. The repository is split into a mobile/web Flutter app, a reusable Dart game engine, transport packages for multiplayer, and a small Dart playtest server.

## Quick Start

Prerequisites:

- Flutter and Dart compatible with the package SDK constraints in each `pubspec.yaml`.
- Platform tooling for the target you want to run, such as Android Studio/Xcode for mobile.

Run the app:

```powershell
cd kalkra
flutter pub get
flutter run
```

Run package tests from a package directory:

```powershell
cd packages/game_engine
dart pub get
dart test
```

There is no checked-in workspace manifest at the repository root, so verification is run per package. Use `flutter` commands for Flutter packages and `dart` commands for pure Dart packages.

## Repository Layout

- `kalkra/` - main Flutter application, including solo play, multiplayer setup/join screens, playtest entry point, persistence, audio, themes, and UI.
- `packages/game_engine/` - pure Dart gameplay logic: number and target generation, solver, validation, scoring, match/session/career helpers, achievements, and Elo.
- `packages/transport_interface/` - shared transport contracts and event models used by network implementations.
- `packages/transport_lan/` - LAN WebSocket transport with NSD discovery, encrypted event payloads, heartbeat, rate limiting, replay checks, and host controls.
- `packages/themer_sdk/` - small Flutter theming helper that parses `.themer` JSON into `ThemeData`.
- `packages/gatekeeper_rate_limit/` - token-bucket rate limiter used by the LAN transport.
- `packages/qr_secure_handshake/` - QR handshake package with examples.
- `playtest_server/` - Dart Shelf server for hosting a Flutter web playtest build and collecting result submissions in SQLite.
- Root docs such as `ARCHITECTURE.md`, `PLAYERS_GUIDE.md`, `GEMINI.md`, and release/planning notes.

## Gameplay Modes

The engine currently exposes `practice`, `endless`, `progressive`, `multiplayer`, `tunnelVision`, `permutations`, `powersOf2`, `tripleThreat`, and `doubleDanger` modes.

- Classic/practice rounds generate one target from six visible numbers.
- Endless starts easier, increases difficulty over time, and tracks lives.
- Progressive uses a fixed ladder of round variants such as gauntlet, forbidden number, two targets, expanding pool, mandatory number, and countdown.
- Tunnel Vision keeps one target while refreshing the number pool.
- Permutations allows multiple submissions and canonicalizes equivalent expressions.
- Powers of 2 uses a specialized number pool and target type.
- Triple Threat shows 9 targets; Double Danger shows 4 targets. Target generation marks a subset as solvable in the engine.
- Jeopardy modifiers can add speed pressure, operator lockout, or double-or-nothing scoring outside progressive mode.

Rules are engine-owned: submitted expressions can only reuse numbers available in the pool, constraints are checked per round, division by zero is rejected, and normal rounds require integer intermediate results unless the round allows fractions.

## Architecture

The app is intentionally thin around the game rules. `game_engine` is the source of truth for generated rounds, solver checks, scoring, and match state. The Flutter app consumes those models through Riverpod providers and screen controllers. Multiplayer flows exchange `GameEvent` objects through the transport interface so UI/game logic is not tied to LAN implementation details.

For set-length matches, `MatchManager` can precompute round data. Endless mode appends generated batches as play progresses. Flutter code can run heavier generation work outside the main UI path to keep gameplay responsive.

## Playtest Server Workflow

The playtest server serves static Flutter web files from `playtest_server/web` and exposes:

- `POST /api/results` - records player name, mode, difficulty, score, round count, timestamp, and metadata.
- `GET /api/stats` - returns the latest 100 stored results.

Typical flow:

```powershell
cd kalkra
flutter build web -t lib/playtest_main.dart

# Copy build/web into ../playtest_server/web, then:
cd ..\playtest_server
dart pub get
dart run bin/server.dart
```

The server listens on `PORT` or `8000` and writes `results.db` in the current `playtest_server` directory.

## LAN Multiplayer and Security Notes

LAN transport uses a host WebSocket server plus NSD registration (`_kalkra._tcp`) for local discovery. Messages are encrypted with a per-session random AES key, clients monitor host heartbeats, hosts can kick clients, host-side rate limiting drops excessive packets, and sequence numbers are used for replay protection after a client identity is known.

This is local-network game transport, not an internet security boundary. The lobby secret must be delivered to clients out of band, such as a QR-code join URL, and clients without the secret cannot decrypt or send accepted messages. Avoid exposing the host port beyond the trusted LAN.

## Verification

Useful focused checks:

```powershell
cd packages/game_engine
dart test

cd ..\transport_interface
dart test

cd ..\transport_lan
flutter test

cd ..\..\kalkra
flutter test
```

There is no tracked root-level test runner in this repository. A practical full sweep is to run `pub get`, `analyze`, and `test` in the app and each package that has a `test/` directory.

## Documentation Caveats

- The root does not define a single workspace manifest or checked-in test runner; commands are run per package.
- Some package descriptions in `pubspec.yaml` are still template text even where code is project-specific.
- LAN client code expects a `secret` query parameter in `connectionInfo`, while at least one transport test still uses a bare `ws://host:port` URL. Treat the secret-bearing URL as the intended secure workflow until tests/code are reconciled.
- Playtest web builds are solo-oriented and submit results to the relative `/api/results` endpoint when running in a browser.
