# Architecture Map - Kalkra

This document maps the architectural structure of the **Kalkra** numbers game, following the technical specifications.

## System Overview

Kalkra is a Flutter-based math game designed for local (LAN) and future cloud multiplayer. It follows a clean architecture with strict dependency isolation.

## Component Breakdown

### 1. Game Engine (`game_engine`)
- **Type:** Pure Dart Package
- **Dependencies:** None (Zero Flutter, Zero I/O)
- **Responsibility:** Core game logic, number generation, expression validation, and solving.
- **Key Modules:**
    - `NumberGenerator`: Generates number pools based on difficulty/presets.
    - `TargetGenerator`: Generates target numbers.
    - `SubmissionValidator`: Validates player mathematical expressions.
    - `SolverEngine`: Finds optimal solutions for the given numbers/target.
    - `ScoreKeeper`: Calculates points based on performance.
    - `RoundManager`: Manages game rounds and timing.
    - `MatchManager`: Scales difficulty and applies Jeopardy across multiple rounds.
    - `CareerManager`: (New) Manages persistent player identity, performance metrics (Speed, Accuracy), and local Elo rankings.

### 2. Transport Layer (`transport_interface`)
- **Type:** Shared Dart Package
- **Responsibility:** Defines the contract for all network communication.
- **Key Contracts:**
    - `IGameTransport`: Interface for hosting and joining sessions.
    - `GameEvent` / `PlayerEvent`: Standardized event types for WebSocket communication.
    - `Models`: `SessionInfo`, `PlayerInfo`, `TeamInfo`, `Submission`, etc.
    - **Handshake:** Exchange of PlayerInfo (Name, Current Elo) during initial connection.
    - **Authority:** Host calculates Elo shifts after match completion and broadcasts updates.

### 3. Transport Implementations
- **LAN Transport (`transport_lan`)**:
    - **Host**: `shelf` server + `shelf_web_socket`.
    - **Client**: WebSocket client.
    - **Discovery**: QR code containing host IP/Port.
- **Null Transport (`null_transport`)**:
    - No-op implementation for solo practice mode.

### 4. Presentation Layer (Flutter App)
- **Framework:** Flutter
- **State Management:** Riverpod
- **Architecture Pattern:** MVVM (Model-View-ViewModel)
- **Key Components:**
    - `TopNavBar`: Unified navigation across all analytical and dashboard views.
    - `GlobalDrawer`: Centralized hamburger menu for 'Main Menu' and 'End Match' actions.
    - `VectorBackground`: Procedural, theme-aligned background textures.
    - `ResponsiveLayout`: Utility widget for unified Mobile/Tablet/Desktop support.
- **Screens:**
    - `MainScreen`: Central dashboard with top-level navigation and performance summary.
    - `GameScreen`: Focused battle arena (non-scrollable) with keyboard support and collapsible pro-tips.
    - `ResultsScreen`: Centered round recap (non-scrollable) with optimal strategy comparison.
    - `StatsScreen`: High-fidelity career analytics and tier progression tracker.
    - `HistoryScreen`: Dedicated battle log and global news feed.
    - `AccountScreen`: Unified identity (callsign) and visual preference (theme) management.
    - `LobbyScreen/JoinScreen`: Multiplayer session management via QR/Discovery.

## Dependency Graph

```text
[ Presentation (Flutter) ]
        |       |
        v       v
[ Game Engine ] [ Transport Implementation ]
        |               |
        v               v
    [ Transport Interface ]
```

## Data Flow
1. **Host** starts session -> `transport_lan` starts `shelf` server.
2. **Host** generates seed -> Broadcasts to all connected **Clients**.
3. **Clients** (including Host as local client) derive same numbers from seed.
4. **Players** submit expressions -> Sent via WebSocket to **Host**.
5. **Host** validates and scores -> Broadcasts results.
6. **Host** calculates career updates (Elo, Stats) -> Broadcasts to all clients.
