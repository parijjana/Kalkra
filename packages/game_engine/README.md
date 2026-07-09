# game_engine

`game_engine` is the pure Dart rules package for Kalkra. It owns number and target generation, expression validation, solving, scoring, match/session state, achievements, career helpers, and Elo calculations.

## Public API

The package exports from `lib/game_engine.dart`:

- `NumberGenerator` and `TargetGenerator` for pools and reachable targets.
- `SubmissionValidator` for parsing expressions, checking number usage, round constraints, and intermediate-result rules.
- `SolverEngine` and `ExhaustiveSolver` for exact/best-solution search.
- `ScoreKeeper` for normal, dual-target, reward-bump, and double-or-nothing scoring.
- `RoundConfig`, `MatchManager`, `SessionManager`, and `GameSettings` for round and match orchestration.
- `CareerManager`, `EloCalculator`, and achievement models/managers.

## Gameplay Modes

`MatchManager` supports `practice`, `endless`, `progressive`, `multiplayer`, `tunnelVision`, `permutations`, `powersOf2`, `tripleThreat`, and `doubleDanger`.

- Standard rounds use six generated numbers and one target.
- Endless mode generates batches and tracks three lives.
- Progressive mode uses a ladder of increasingly constrained rounds.
- Tunnel Vision reuses one target across refreshed number pools.
- Permutations allows multiple submissions and canonicalizes expression forms.
- Triple Threat and Double Danger generate multi-target boards.
- Optional jeopardy events include speed demon, operator lockout, and double or nothing.

## Design Notes

The engine is the source of truth for gameplay integrity. UI code should not duplicate solvability, score, or expression validation rules. Round generation is deterministic when seeded, which helps reproduce solver and scoring behavior in tests.

Normal validation rejects unavailable or reused numbers, division by zero, invalid syntax, failed round constraints, and fractional intermediate results unless the round permits them. Advanced rounds can allow negative or fractional intermediates through `RoundConfig`.

## Testing

```powershell
dart pub get
dart analyze
dart test
```

Tests cover target generation, solver behavior, submission validation, scoring, match/session management, multiplayer scoring/team helpers, career state, and regression cases.

## Caveats

- Some serialized round data is intentionally simplified, such as storing `config.title` rather than the full config object.
- Triple Threat and Double Danger generation currently returns board targets and treats generation as solvable by construction; consult target-generator tests before changing those rules.
