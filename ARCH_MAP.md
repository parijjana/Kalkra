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
- **Screens:**
    - `MainScreen`: Entry point, solo/multiplayer selection.
    - `LobbyScreen`: Session setup, QR display.
    - `JoinScreen`: QR scanner.
    - `GameScreen`: Interactive board, live player list (Responsive: Mobile/Tablet/Web).
    - `ResultsScreen`: Score summaries and solver reveal.
    - `ProfileScreen`: (New) Identity setup and name collision preview.
    - `StatsScreen`: (New) High-fidelity dashboard for career progression and rival history.

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
