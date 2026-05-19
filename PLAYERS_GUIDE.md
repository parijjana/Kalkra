# KALKRA Player's Guide

Welcome to **Kalkra**, the high-intensity math puzzle arena. Whether you're training solo or competing in the global multiplayer arena, this guide will help you master the vectors.

## 🕹️ Core Gameplay
The goal is simple: use **6 token numbers** and basic operators (**+**, **-**, **×**, **÷**) to reach a **Target Number**.

### Basic Rules:
1.  Each token number can be used **only once**.
2.  Intermediate results must be **positive integers** (unless playing in Advanced Mode).
3.  You have a limited time (default 30s) to submit your expression.

---

## 🏆 Game Modes

### 1. Classic & Practice
Standard math puzzle. Get as close as possible to the target.

### 2. Triple Threat (The Grid)
A 3x3 grid of 9 numbers is shown. Only **3 are solvable**.
*   **Goal:** Compute exactly 1 of the 3 solvable targets.
*   **Scoring:** 10pts (Largest target), 7pts (Middle), 5pts (Smallest).
*   **Constraint:** No points for "near misses." Exact match only.

### 3. Double Danger
A simplified 2x2 version of Triple Threat.
*   **Goal:** Pick 1 of 2 solvable targets.
*   **Scoring:** 10pts (Largest), 7pts (Smallest).

### 4. Tunnel Vision
A single target persists for multiple rounds. Every round gives you a new pool of tokens to reach the *same* target.

### 5. Progressive (The Ladder)
A sequence of rounds with increasing difficulty and shifting constraints. Surviving the ladder is the ultimate test of speed and logic.

### 6. Endless
Survive as long as possible. The targets get harder, and the timers get shorter. You have 3 lives; missing a target loses a life.

---

## ⚡ Jeopardy Modes
Jeopardy events trigger randomly in multiplayer and advanced solo matches, adding dynamic modifiers to the round.

| Jeopardy Type | Effect | Player Strategy |
| :--- | :--- | :--- |
| **Speed Demon** | Timer is reduced by 50%. | Prioritize a quick "good enough" solution over an exact one. |
| **Operator Lockout** | One operator (e.g., ×) is BANNED. | You must find a path using only the remaining 3 operators. |
| **Double or Nothing** | Exact match = 20pts. Anything else = 0pts. | High risk, high reward. Only submit if you are certain. |

---

## 📊 Scoring Mechanics
*   **Exact Match:** 10 Points (Standard).
*   **Off by 1:** 7 Points.
*   **Off by 2:** 5 Points.
*   **Off by 3-5:** 3 Points.
*   **Off by 6-10:** 1 Point.
*   **Multi-Target Bonus:** In Triple Threat/Double Danger, points are based on which solvable target you hit (Largest = Most Points).

---

## 🔒 Security & Fair Play
Kalkra uses **Hardware-Backed Integrity Checks** (Android Keystore/iOS Keychain) to ensure scores and Elo ratings are untamperable. Multi-round targets are generated in background isolates to ensure zero lag and prevent local state manipulation.
