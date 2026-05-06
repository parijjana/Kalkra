# APP_MAP.md - Kalkra Application Map

This document provides a high-fidelity catalog of all screens, their core functionalities, and associated project files down to the method level.

---

## 1. Dashboard (Main Screen)
**File:** `kalkra_app/lib/src/screens/main_screen.dart`
**ID:** `MainScreen`

### Functionality:
- **Central Navigation Hub:** Provides entry points to all game modes and sub-screens.
- **Career Quick-View:** Displays current ELO and player name in a high-contrast badge.
- **Performance Summary (Desktop):** Shows high-level stats (Avg Speed, Accuracy, Best Streak).
- **Responsive Layouts:** Separate `_MainScreenMobile` and `_MainScreenDesktop` for tailored experiences.

### Key Methods:
- `_showMultiplayerDialog(context)`: Displays bottom sheet for Host/Join selection (Mobile).
- `_EloBadge.build`: Renders the adaptive ELO and player name identity card.
- `_DesktopStatsPanel.build`: Renders high-density performance metrics for wide screens.

---

## 2. Solo Mission & Game Loop
**Files:** 
- `kalkra_app/lib/src/screens/match_setup_screen.dart`
- `kalkra_app/lib/src/screens/game_screen.dart`
- `kalkra_app/lib/src/screens/results_screen.dart`

### Functionality:
- **Match Configuration:** Select difficulty and game mode (Classic, Progressive, Endless).
- **Active Gameplay:** Interactive number and operator tiles for expression building.
- **Reactive Visuals:** Background Aura responds to timer panic, proximity, and operations.
- **Outcome Analysis:** Detailed comparison of player's solution vs. Solver's optimal result.

### Key Methods (GameScreen):
- `_onNumberTap(index, value)`: Handles tile selection and expression concatenation.
- `_onOperatorTap(op)`: Handles operator addition and triggers Aura impact animations.
- `_updateProximity()`: Real-time calculation of distance to target for Aura intensity.
- `_submit()`: Validates expression, triggers Achievement checks, and ends round.
- `_handleKeyEvent(event)`: Desktop-first keyboard shortcuts (Arrow keys, Space, HJKL).

---

## 3. Multiplayer Host (Command Center)
**Files:**
- `kalkra_app/lib/src/screens/host_screen.dart`
- `kalkra_app/lib/src/screens/spectator_screen.dart`

### Functionality:
- **Lobby Management:** QR code and MDNS discovery for local players to join.
- **Spectator Control:** Real-time visibility into all players' submission status.
- **Jeopardy Management:** Host can toggle "Next Round Jeopardy" to force higher stakes.
- **Player Moderation:** Kick or Ban players directly from the command grid.

### Key Methods (SpectatorScreen):
- `_onTimeUp()`: Aggregates all player results, calculates ELO shifts, and broadcasts outcome.
- `_handleGameEvent(event)`: Synchronizes match state (numbers/targets) across the LAN.
- `_kickPlayer(id)` / `_banPlayer(id, deviceId)`: Triggers transport-layer removal of participants.

---

## 4. Multiplayer Staging (Lobby)
**File:** `kalkra_app/lib/src/screens/staging_screen.dart`
**ID:** `StagingScreen`

### Functionality:
- **Team Assignment:** Drag and drop players into one of 4 team zones.
- **Ready System:** Tracks individual readiness before allowing the host to start.
- **Lobby Sync:** Real-time synchronization of team positions and ready states across all clients.

### Key Methods:
- `_assignTeam(playerId, teamId)`: Updates local state and broadcasts new team assignments.
- `_toggleReady(ready)`: Informs the host of player readiness.
- `_startMatch()`: Host-only trigger to transition all participants to the game.

---

## 5. Multiplayer Join
**File:** `kalkra_app/lib/src/screens/join_screen.dart`
**ID:** `JoinScreen`

### Functionality:
- **Automatic Discovery:** Scans Wi-Fi for active Kalkra hosts via MDNS.
- **Direct Joining:** QR scanner and manual IP entry for quick lobby entry.

### Key Methods:
- `_startDiscovery()`: Initializes `nsd` listener for `_kalkra._tcp` services.
- `_join(connectionInfo)`: Establishes `LanClientTransport` and handshakes with host.

---

## 5. Analytics & Metrics
**File:** `kalkra_app/lib/src/screens/stats_screen.dart`
**ID:** `StatsScreen`

### Functionality:
- **Performance Visualization:** Charts for ELO history, speed trends, and accuracy.
- **Rivalry Tracker:** List of recent opponents and ELO outcomes.

### Key Methods:
- `_buildEloChart(colorScheme)`: Generates line graphs for ELO progression.
- `_buildRivalsList(career)`: Lists recent match history with win/loss indicators.

---

## 6. Achievements Gallery
**File:** `kalkra_app/lib/src/screens/achievements_screen.dart`
**ID:** `AchievementsScreen`

### Functionality:
- **Trophy Room:** Visual grid of 100+ achievements categorized by style.
- **Secret Discovery:** Logic to obfuscate hidden/locked achievements.

### Key Methods:
- `_buildAchievementsGrid(context, ref)`: Filters and renders achievement cards from `AchievementRegistry`.
- `_AchievementTile.build`: Adaptive card that illuminates upon unlock.

---

## 7. Match Summary
**File:** `kalkra_app/lib/src/screens/match_summary_screen.dart`
**ID:** `MatchSummaryScreen`

### Functionality:
- **Victory Podium:** Proclaims the winning team with high-impact typography.
- **Burnup Chart:** Visualizes round-by-round point acquisition for each team.
- **Match MVP:** Highlights the top-performing player across all categories.
- **Lobby Re-entry:** Allows the host to reset the match while keeping all players and teams in the session.

### Key Methods:
- `_BurnupChart.build`: Renders dynamic progress bars per team.
- `onPressed (Return to Lobby)`: Resets per-match state and broadcasts `matchEnded` event.

---

## 8. Session Recap
**File:** `kalkra_app/lib/src/screens/session_recap_screen.dart`
**ID:** `SessionRecapScreen`

### Functionality:
- **Long-Term Leaderboard:** Tracks cumulative points and wins across multiple matches in a single session.
- **Match History Log:** Displays a scrollable list of all match outcomes for the current session.

---

## 9. Account & Identity
**File:** `kalkra_app/lib/src/screens/account_screen.dart`
**ID:** `AccountScreen`

### Functionality:
- **Identity Management:** Update player name and view career summary.
- **Theme Selection:** Global visual theme switcher (Noir, Neon, Pastel, etc.).
- **Data Persistence:** Reset career or manage local settings.

### Key Methods:
- `_buildIdentityCard(colorScheme)`: Interface for name editing.
- `_buildThemeGrid(context, ref)`: Grid of theme selection cards.

---

## 8. Core Engine Integration
**Folder:** `packages/game_engine/lib/src/`

### Key Functional Links:
- **Validation:** `submission_validator.dart` -> Used by `GameScreen` and `SpectatorScreen` for rule enforcement.
- **Persistence:** `career_manager.dart` -> Backs the `Account` and `Stats` screens.
- **State Machine:** `match_manager.dart` -> Logic for round transitions and game modes.
- **Evaluation:** `solver_engine.dart` -> Powers the "Optimal Solution" view on `ResultsScreen`.
- **Achievements:** `achievement_manager.dart` -> Event-driven listener that triggers notifications.
