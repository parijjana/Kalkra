# Kalkra Playtest Server

This is a lightweight Dart Shelf server for web playtests. It serves a Flutter web build from `playtest_server/web` and stores submitted results in a local SQLite database named `results.db`.

## Endpoints

- `POST /api/results` - accepts JSON with `player_name`, `mode`, `difficulty`, `score`, `total_rounds`, `timestamp`, and optional `metadata`.
- `GET /api/stats` - returns the latest 100 stored result rows.

Static files are served after API routes, with `index.html` as the default document.

## Build the Playtest Web App

From the app directory:

```powershell
cd ..\kalkra
flutter pub get
flutter build web -t lib/playtest_main.dart
```

Copy the generated `kalkra/build/web` directory to `playtest_server/web`.

## Run the Server

```powershell
cd playtest_server
dart pub get
dart run bin/server.dart
```

By default the server listens on `0.0.0.0:8000`. Override the port with the `PORT` environment variable:

```powershell
$env:PORT = "9000"
dart run bin/server.dart
```

Open `http://localhost:8000` locally, or share `http://YOUR_LAN_IP:8000` with testers on the same network.

## Data

The server creates this table if needed:

- `results(id, player_name, mode, difficulty, score, total_rounds, timestamp, metadata)`

The database is stored in the current working directory. Delete or archive `results.db` when you want a clean playtest run.

## Production Notes

This server is for lightweight playtesting. It does not implement authentication, abuse protection, migrations, or administrative controls. Run it only on a trusted network or behind infrastructure that provides those protections.

For macOS-specific launch and AOT compilation notes, see `README_MACOS.md`.
