# Regression Suite - Kalkra

## Core Engine (Packages/game_engine)
- [x] **Number Generation:** Verified 1-large/5-small pool distribution for standard mode.
- [x] **Number Generation:** Verified 4-token pool for Easy mode.
- [x] **Target Generation:** Verified difficulty-weighted target ranges (100-999).
- [x] **Solver Engine:** Backtracking solver finds exact solutions within < 50ms.
- [x] **Solver Engine:** Nesting depth restricted to 1 for Easy mode.
- [x] **Score Keeper:** Verified absolute difference scoring (10/7/5 pts).
- [x] **Jeopardy:** Verified Speed Demon (30s) and Operator Lockout functionality.
- [x] **Match Manager:** State transitions (idle -> playing -> scoring) verified.
- [x] **Endless Mode:** 3-life system correctly terminates match on 0-score rounds.
- [x] **Progressive Mode:** Automatic difficulty scaling across 10 rounds verified.

## Communication (Packages/transport_lan)
- [x] **WebSocket Handshake:** Host correctly broadcasts session state.
- [x] **Join Protocol:** Clients can join via IP/QR and receive initial round data.
- [x] **Submission Sync:** Player expressions sent to host and acknowledged.
- [x] **Results Broadcast:** Host correctly calculates and syncs round results.

## Application UI (kalkra_app)
- [x] **Responsive Layout:** Adaptive UI for Mobile (Portrait) and Desktop (Ultrawide).
- [x] **Solo Mode:** Flow from Match Setup -> Game -> Results verified.
- [x] **Multiplayer Host:** Role selection (Player/Spectator) verified.
- [x] **Spectator Dashboard:** Real-time blind player grid and Jeopardy override verified.
- [x] **Analytics:** Unified stats and 50-entry match history log verified.
- [x] **Keyboard Navigation:** Arrow keys and HJKL operators fully functional on Windows.
- [x] **Theme Switcher:** Dynamic transitions between Noir, Neon, and Pastel.

## Tiered Progression (Phase 10)
- [x] **Constraint Validation:** Verified `OperationsBlackoutConstraint` correctly bans operators.
- [x] **Number Generation:** Verified `PoolType.smallOnly` and `PoolType.primesOnly` distributions.
- [x] **Multi-Target Logic:** Verified dual targets are generated and scored correctly (proximity to nearest).
- [x] **Round Ladder:** Verified 8-round progression sequence in Progressive mode.
- [x] **Reward Bumps:** Verified extra points for exact matches in specialized rounds.

## Multi-Platform Verification
- [x] **Android:** APK build and physical device installation successful (moto g57).
- [x] **Windows:** Release executable build successful and functional.
- [x] **Web:** Compilation and basic functionality verified.

## Meta-Progression & Visuals (Phase 11)
- [x] **Reactive Aura:** Verified visual reaction to timer panic (red shift/pulse).
- [x] **Reactive Aura:** Verified proximity glow intensity as score nears target.
- [x] **Reactive Aura:** Verified operator-specific impact animations (+, -, *, /).
- [x] **Achievement Core:** Verified event-driven unlocking logic for Speed, Precision, and Quirky categories.
- [x] **Achievement Persistence:** Verified saving/loading of unlocked IDs in `CareerManager`.
- [x] **Achievement UI:** Verified notification overlay triggers on unlock.
- [x] **Achievement UI:** Verified "Secret Achievement" (???) obfuscation in the account gallery.

## Unified Navigation & Hub (Phase 12)
- [x] **Global Drawer:** Verified persistence on Dashboard across mobile/desktop.
- [x] **Global Drawer:** Verified deep links to Solo, Host, Join, and Metric screens.
- [x] **Global Drawer:** Verified Branding Header ELO and name synchronization.
- [x] **Top Nav Bar:** Verified tab-based navigation consistency on desktop.

## Solo Player Refinement (Phase 16)
- [x] **Solo Summary:** Verified dedicated post-match summary screen for solo players.
- [x] **Conditional Navigation:** Verified `ResultsScreen` logic correctly routes to `SoloSummaryScreen` (Solo) vs `MatchSummaryScreen` (Multiplayer).
- [x] **Global Navigation:** Verified `navigatorKeyProvider` successfully restores app to `MainScreen` on network errors.

## Multiplayer Teams & Staging (Phase 13)
- [x] **Staging Lobby:** Verified players joining appear in "Unassigned" pool.
- [x] **Team Assignment:** Verified Drag & Drop assignment into 4 team zones.
- [x] **Dynamic Scaling:** Verified Teams 3 & 4 only show when player count > 3.
- [x] **Team Scoring:** Verified best response per team is awarded points in `SessionManager`.
- [x] **Ready System:** Verified "Start Match" is locked until all assigned players are ready.
- [x] **Join Overlay:** Verified QR code and URI persist on Staging Screen.
- [x] **Lobby Randomizer:** Verified host can shuffle unassigned players into teams.
- [x] **Wait Time:** Verified 15-second lockout on Results screen for Player-Hosts.
- [x] **New Jeopardies:** Verified 'Target Obfuscation' and 'Blind Pool' UI logic.

## Retroactive TDD & Sync (Phase 15)
- [x] **Auto-Navigation:** Verified simultaneous transition from Lobby to Game via widget tests.
- [x] **Early Termination:** Verified host triggers round end immediately upon all player submissions via widget tests.
- [x] **Lobby Sync:** Verified team renaming on host propagates to all participants via widget tests.
- [x] **Client Identity:** Verified 'solo' label fix by ensuring clients initialize MatchManager on sync.

---
*Last Verified: 2026-05-01*
