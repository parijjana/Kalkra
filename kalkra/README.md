# Kalkra App

This directory contains the main Flutter application for Kalkra. It wires the reusable `game_engine` package into screens, Riverpod providers, persistence, audio, themes, LAN multiplayer flows, and the web playtest entry point.

## Run Locally

```powershell
flutter pub get
flutter run
```

For web playtesting, build the dedicated entry point:

```powershell
flutter build web -t lib/playtest_main.dart
```

Copy the generated `build/web` directory into `../playtest_server/web` before starting the playtest server.

## App Structure

- `lib/main.dart` - normal app entry point.
- `lib/playtest_main.dart` - web playtest entry point with fixed pastel theme and playtest login.
- `lib/src/screens/` - game, setup, join/host, staging, results, guide, account, stats, and policy screens.
- `lib/src/providers/` - Riverpod providers and controllers for game state, career state, and hosted sessions.
- `lib/src/services/` - sound, persistence/security helpers, playtest result submission, and vault storage.
- `lib/src/widgets/` - reusable UI pieces for gameplay, staging, navigation, and responsive layout.
- `lib/src/theme/` - app theme definitions and theme provider.

## Gameplay Surface

The app presents solo and multiplayer flows over the engine modes: practice/classic play, endless, progressive ladder, tunnel vision, permutations, powers of 2, Triple Threat, and Double Danger. Match setup and game screens consume precomputed `MatchRoundData` from the engine, while scoring and expression validation remain engine-owned.

## Multiplayer

LAN multiplayer depends on `transport_interface` and `transport_lan`. Host and join screens use shared event models for lobby updates, readiness, teams, round starts/results, kicks, heartbeats, and match endings. The LAN transport encrypts WebSocket payloads with a per-lobby secret and is intended for trusted local networks.

## Playtest Mode

`lib/playtest_main.dart` starts a simplified web app for collecting gameplay feedback. `PlaytestService` stores the player name locally and posts results to `/api/results` in browser builds, or `http://localhost:8000/api/results` in native runs.

## Verification

```powershell
flutter analyze
flutter test
```

For a broader repository sweep, run equivalent `pub get`, `analyze`, and `test` commands in the other packages as well.

## Caveats

- Generated Riverpod code is present in the tree; regenerate it with the project build runner workflow when changing annotated providers.
- The playtest build is not the full production app surface.
- Platform-specific app signing, icons, and deployment assets live under `android/`, `ios/`, `web/`, and other Flutter platform directories.
