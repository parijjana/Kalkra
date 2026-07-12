# Kalkra — Single-Player Pivot (supersedes parts of REMEDIATION_PLAN.md)

**Date:** 2026-07-12
**Decision:** Ship single-player only to Mac App Store, iOS App Store, and Microsoft Store. Local multiplayer (a stepping stone toward eventual online multiplayer) is removed from store builds and replaced with a "Coming Soon" placeholder.

**Code preservation:** Full multiplayer implementation is preserved at git tag **`multiplayer-baseline`** (commit `de0448c`, pushed history at github.com/parijjana/Kalkra). Recover any file with `git show multiplayer-baseline:<path>`, or branch from the tag. The `packages/` directory (transport_lan, gatekeeper_rate_limit, qr_secure_handshake, etc.) stays in the repo untouched — it simply is no longer compiled into the app.

---

## Issues eliminated by the pivot

From SECURITY_ANALYSIS.md: **S1** (unauthenticated transport crypto), **S2** (join replay/hijack), **S5** (device IDs sent to peers), **S6** (broken discovery join), **S8** (NSD broadcast) — all multiplayer-only code paths, no longer shipped.

From STORE_POLICY_ANALYSIS.md: **M2** (camera + Bonjour keys on macOS), **I1** (iOS camera crash), **I2** (iOS local-network keys), **W1** (mobile_scanner Windows crash) — the plugins that required them are removed. macOS entitlements also simplify: no `network.server`, no camera entitlement needed.

These issues become relevant again only when multiplayer returns; fix S1/S2/S5/S6 at that time (the analysis stands).

## Issues that REMAIN (single-player still needs these)

| # | Issue | Complexity |
|---|---|---|
| R1 | **M1** — enable App Sandbox in both macOS entitlements files (now needs no network entitlements at all once R3/R4 land) | haiku |
| R2 | **M3/I3** — `ITSAppUsesNonExemptEncryption` on iOS + macOS (save-file AES via `encrypt` still ships); `CFBundleDisplayName` → "Kalkra" | haiku |
| R3 | **S3** — playtest telemetry auto-submits from SoloSummaryScreen (a *solo* flow) — gate out of store builds | sonnet |
| R4 | **I4** — bundle Google Fonts, disable runtime fetching | sonnet |
| R5 | **W2** — MSIX packaging config (capabilities now reduce to none/`internetClient` only if url_launcher links remain) | sonnet |
| R6 | **X1** — rewrite + host privacy policy (much simpler now: pure local-first is nearly true; drop the LAN-sharing section or mark it future) | sonnet |
| R7 | **X2** — rename "Jeopardy" modifiers (trademark) | haiku |
| R8 | **S4** — legacy save-key fallback migration + constant-time HMAC compare | sonnet |
| R9 | **W3/I6** — in-app privacy policy link, store questionnaires, IARC/age ratings, screenshots, WACK run | paperwork |

After R3 + R4, the app makes **zero network requests** (except user-initiated url_launcher links) — "Data Not Collected" on Apple's nutrition label and a minimal-permission MSIX. That is an exceptionally clean review posture.

## Revised estimate

- Strip refactor: ~1 day (in progress, delegated)
- R1–R8: ~2 days
- R9 paperwork + per-platform regression (sandboxed macOS build, iOS device, installed MSIX): ~1–2 days

**Total: roughly 4 working days to submission-ready on all three stores** — versus 4–7 with multiplayer included, and with the two opus-level crypto redesign tasks deferred entirely.

## Opinion recorded at decision time

Right call. The multiplayer stack was the source of every crash-in-review bug, all privacy-label complications, and both hard security findings — while being, by the developer's own assessment, a stepping stone not a launch feature. Shipping a genuinely offline, zero-permission math game is the fastest path to players, and player traction is the stated precondition for investing in online multiplayer anyway. When multiplayer returns, rebuild the join flow on an authenticated cipher (AES-GCM) from day one rather than retrofitting.
