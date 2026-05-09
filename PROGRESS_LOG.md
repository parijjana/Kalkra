# Progress Log - MathGame (Kalkra)

## 2026-05-08
- [INIT] Initialized `PROGRESS_LOG.md` and `ARCHITECTURE.md`.
- [STRATEGY] Replaced manual `REGRESSION_SUITE.md` with automated `tool/verify.dart`.
- [TOOL] Created `tool/verify.dart`: Portable, multi-package health checker.
- [GIT] Added `.gitignore` to ignore `tool/` and common Dart/Flutter artifacts.
- [CHECK] Baseline health check complete: 7 packages detected, 0/7 clean (expected WIP state).

## 2026-05-09
- [OPTIM] SolverEngine: Implemented 3.7x faster solver with early-exit and MDAS precedence building.
- [RULE] SolverEngine: Pruned trivial operations (*1, /1) to reduce search space.
- [MODE] Implemented "Tunnel Vision": Target persists while tokens/operators change (pre-verified solvable).
- [MODE] Implemented "Permutations": Deduplicated multi-solution mode using mathematical canonical forms.
- [PERF] Background Isolate: Moved match pre-computation to background threads via Flutter's `compute()`.
- [UI] Created `CalibrationScreen`: Dedicated quirky loading experience for background math.
- [UI] Redesigned `MatchSetupScreen`: Decoupled game mode from round count for better flexibility.
- [UI] Added "RESTART MATCH" to `SoloSummaryScreen`: Preserves settings for immediate replay.
- [RULE] Refined Jeopardy distribution: Guaranteed 1-3 events per match; increasing frequency in Endless.
- [FIX] Resolved infinite loop in `TargetGenerator` and timer leak in `GameScreen`.
- [MODE] Implemented "2's Powers" & "3's Powers": 4-digit themed math challenges (excluding token '1').
- [UI] Dashboard Redesign: Overhauled `MatchSetupScreen` into a two-pane "Mission Control" center.
- [UI] Results Refactor: Highlight player solution as hero; hide solver on exact match; rename to "Possible Solution".
- [RULE] Integrity Purge: Removed all hidden/obfuscated number mechanics (`?` and expressions).
- [FIX] Navigation: Corrected "End Match" state reset and forced redirect to Main Screen.
- [BACKEND] Playtest System: Deployed Dart Shelf AOT server with SQLite tracking and Pastel theme for web.
- [MANDATE] Created `GEMINI.md`: Core gameplay integrity and performance rules.
