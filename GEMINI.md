# KALKRA Project Mandates

## Gameplay Integrity
- **No Hidden Numbers**: Tokens and targets MUST always be displayed as raw numerical values. Never use "?" or obfuscation strings (like "10 + 20") to hide the actual target. This applies even to Jeopardy and specialized modes.
- **Engine Priority**: The game engine logic (solvability, solver) is the source of truth and must remain consistent across all platforms (Mobile, Web).

## UI/UX Standards
- **Pastel Theme**: Default theme for playtesting to ensure high legibility.
- **Mission Control**: Scalable multi-pane layout for setup screens.
- **Early Exit Solver**: Performance is a feature; always prefer early-exit and lazy materialization for the math solver.
