# Architecture Map - MathGame (Kalkra)

## Overview
A high-stakes math competition game (Kalkra) built with Flutter. It features a multi-package architecture to separate core engine logic, networking, and UI.

## Workspace Structure
- **kalkra_app/**: The main Flutter application.
    - **lib/src/screens/calibration_screen.dart**: Engages the user while background math logic runs.
    - **lib/src/screens/match_setup_screen.dart**: Decouples game mode from round count.
- **packages/**
    - **game_engine/**: Core math logic.
        - **lib/src/match_manager.dart**: Orchestrates full-match pre-computation.
        - **lib/src/solver_engine.dart**: High-performance, early-exit math solver.
- **playtest_server/**: Lightweight Dart Shelf backend for web playtesting.
    - **bin/server.dart**: AOT-ready server serving static web files and tracking results via SQLite.

## Game Generation Strategy
- **Full-Match Pre-computation**: For set-length matches (3, 5, 10 rounds), the `MatchManager` generates and verifies all rounds as solvable *before* the match starts.
- **Async Isolates**: Heavy math (Solver iterations) is offloaded from the main UI thread to background isolates via Flutter's `compute()` to maintain 60/120 FPS.
- **Dynamic Refill**: Endless mode generates a small buffer (10 rounds) and replenishes it in the background as the player progresses.

## Deployment & Environments
- **Mobile**: Full-featured Flutter app for Android/iOS (Isolates, Bluetooth/LAN multiplayer).
- **Web (Playtest)**: Scaled-down "Solo Only" build with server-side result tracking for rapid gameplay feedback.
- **Pi Zero / Mac Server**: Dart Shelf AOT binaries for low-power network hosting.

## Verification & Quality
- **tool/verify.dart**: Unified health check tool for analysis and testing across all packages.
- **GEMINI.md**: Mandated rules for gameplay integrity (e.g., no hidden numbers) and technical standards.
