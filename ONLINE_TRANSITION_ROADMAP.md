# Kalkra Online Multiplayer: Roadmap & Fiscal Analysis

This document outlines the transition from LAN to Online Multiplayer and provides a cost-benefit analysis for scaling the game as a hobby project.

---

## 1. Technical Transition Roadmap

### Phase A: Authoritative Logic (The Backend)
*   **Central Game Server**: Build a Dart-based backend using `shelf` or `functions_framework`. This server will use the existing `game_engine` package to ensure identical math logic.
*   **Stateful WebSockets**: Move from P2P to a central hub. Clients connect to the server; the server handles lobby creation, player matching, and event broadcasting.
*   **Validation**: Server performs all math evaluations. Clients only submit raw expression strings.

### Phase B: Infrastructure & Discovery
*   **Room Code Service**: A global registry mapping 6-digit codes to active WebSocket instances.
*   **STUN/TURN**: Not strictly required if using a central WebSocket relay, but necessary if keeping a Hybrid P2P model.
*   **Global Matchmaking**: Logic to pair players by ELO range.

### Phase C: Identity & Persistence
*   **Firebase Authentication**: Support Google/Apple login.
*   **Secure Database**: Move career stats to Firestore or MongoDB.
*   **TLS (WSS)**: Enforce encrypted tunnels for all traffic.

---

## 2. Cloud Solution Estimations

We recommend a **Serverless/PaaS** stack (like Firebase) to minimize maintenance for a hobby project.

### Tier 1: The "Hobbyist" (100 MAU)
*   **Stack**: Firebase Free Tier (Spark Plan).
*   **Auth**: 50,000 monthly active users (Free).
*   **Database**: 50k reads / 20k writes per day (Free).
*   **Real-time Traffic**: 100 simultaneous connections (Free).
*   **Estimated Cost**: **$0 / month**.
*   **Verdict**: Perfectly manageable as a side project.

### Tier 2: The "Rising Indie" (10,000 MAU)
*   **Stack**: Firebase Blaze Plan (Pay-as-you-go).
*   **Database**: Assuming 10 matches/day per user. Total ~3M writes/month.
*   **Traffic**: 10k users * 50kb per match = ~500MB egress.
*   **Estimated Cost**: **$5 – $15 / month**.
*   **Breaking Point**: This is where you exit the free tier. Egress and Firestore write limits will be the first to trigger costs.

### Tier 3: The "Viral Success" (100,000 MAU)
*   **Stack**: Scaled Backend (AWS ECS or Firebase Scaled).
*   **Compute**: Dedicated WebSocket nodes.
*   **Database**: High-frequency ELO updates and global leaderboards.
*   **Estimated Cost**: **$150 – $400 / month**.
*   **Verdict**: Requires significant optimization (caching, batching) to keep costs down.

---

## 3. Fiscal Strategy & Monetization

Since the goal is to **not spend out of pocket**, we recommend the following models based on usage:

### Option A: The "Freemium" Model (Recommended)
*   **The Hook**: Core game is 100% free for Solo and LAN play.
*   **The Fee**: Charge a **$1.99 one-time "Global Arena" unlock**.
*   **Math**: At 10k MAU, if 2% of users (200 people) buy the unlock, you earn ~$400. This pays for Tier 2 infrastructure for over 2 years.

### Option B: The "Ad-Supported" Model
*   **Fiscal Sense**: Typical eCPM is $1.50 per 1,000 impressions.
*   **Break-even**: To cover a $15 monthly cloud bill, you need ~10,000 full-screen ad views per month.
*   **UX Impact**: Ads can feel "cheap" for a premium Noir-themed app. We recommend **Rewarded Ads** (e.g., watch an ad to get a second chance in Endless mode) rather than banners.

### Option C: Community Support
*   Add a "Buy me a Coffee" or "Sponsor a Server" button in the Account settings. For a hobby project, loyal users often contribute enough to cover small AWS/Firebase bills.

---

## 4. The "Kill-Switch" Protocol
For a zero-cost hobby project, implement a **Budget Alert** in your cloud provider.
1.  Set a hard cap of $5/month.
2.  If the cap is hit, the app automatically disables the "Online" button and shows a "Maintenance: Server Capacity Reached" message.
3.  LAN and Solo play remain functional (since they cost $0).

---

## 5. Strategic Recommendation
**Don't build the backend yet.** 
Continue to polish the "Secure LAN" version. If you see high organic demand for an online mode, implement the **Authoritative Logic** first and launch on the **Firebase Free Tier**. Only consider monetization once you hit the 5,000 MAU mark.
