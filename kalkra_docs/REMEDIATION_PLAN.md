# Kalkra — Remediation Plan for Mac / iOS / Microsoft Store Submission

**Date:** 2026-07-12
**Companion docs:** `SECURITY_ANALYSIS.md` (S-issues), `STORE_POLICY_ANALYSIS.md` (M/I/W/X-issues).

Work is organized into four phases. Phases 1–2 are submission blockers. Each task carries a complexity tag used for agent delegation: **[haiku]** trivial/mechanical, **[sonnet]** standard coding, **[opus]** complex/design-sensitive.

---

## Phase 1 — Submission blockers: platform configuration (1 day)

These are config-only changes with outsized impact; all guaranteed-rejection items live here.

### 1.1 macOS entitlements + Info.plist — fixes M1, M2, M3 [haiku]
- `macos/Runner/Release.entitlements` and `DebugProfile.entitlements`: set `com.apple.security.app-sandbox` → `true`; add `com.apple.security.network.server`, `com.apple.security.network.client`, `com.apple.security.device.camera` (keep `allow-jit` in DebugProfile only).
- `macos/Runner/Info.plist`: add `NSCameraUsageDescription`, `NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_kalkra._tcp`), `ITSAppUsesNonExemptEncryption` (false — standard/exempt algorithms).
- **Acceptance:** app builds; sandbox verified via `codesign -d --entitlements`.

### 1.2 iOS Info.plist — fixes I1, I2, I3 (partial) [haiku]
- Add `NSCameraUsageDescription`, `NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_kalkra._tcp`), `ITSAppUsesNonExemptEncryption`.
- Change `CFBundleDisplayName` from "Kalkra App" to "Kalkra" (X3).
- **Acceptance:** Join screen opens on a physical iOS device without crashing; local-network permission prompt appears.

### 1.3 Windows MSIX packaging — fixes W2 [sonnet]
- Add `msix` dev dependency; configure identity, publisher, display name, logo, and capabilities `internetClient`, `internetClientServer`, `privateNetworkClientServer` in `pubspec.yaml`.
- **Acceptance:** `dart run msix:create` produces an installable package; LAN host + join work **from the installed MSIX**.

### 1.4 Gate QR scanner by platform — fixes W1 [sonnet]
- `join_screen.dart`: render `MobileScanner` only on platforms the plugin supports (Android/iOS/macOS/web); on Windows show manual entry + a "scan on your phone / ask host for code" affordance.
- **Acceptance:** Join screen opens on Windows without exceptions; scanner still works on iOS/macOS.

### 1.5 Sandbox regression test on macOS [no code — verification]
- Re-run full multiplayer flow (host, discover, QR join, kick, disconnect) under the sandboxed build. Log any breakage as new Phase 2 tasks. `systemGUID` may return null under sandbox — Task 2.3 removes the dependency on it anyway.

---

## Phase 2 — Submission blockers: privacy-truth alignment (1–2 days)

Goal: make "Data Not Collected" the truthful answer on every store questionnaire.

### 2.1 Remove playtest telemetry from store builds — fixes S3 [sonnet]
- Gate `PlaytestService.submitResult` call in `solo_summary_screen.dart` behind a compile-time flag (`bool.fromEnvironment('PLAYTEST')` or a separate widget wired only from `playtest_main.dart`).
- **Acceptance:** store-flavored build makes zero HTTP requests during a full solo match (verify with a proxy or debug network log).

### 2.2 Bundle fonts, disable runtime fetching — fixes I4 [sonnet]
- Download the used Google Fonts families (Space Grotesk, Plus Jakarta Sans, DM Sans, IBM Plex Sans, Nunito Sans — enumerate from `app_theme.dart`), add to `assets/fonts/` + `pubspec.yaml`, set `GoogleFonts.config.allowRuntimeFetching = false` in `main.dart`. Keep OFL license file in assets.
- **Acceptance:** first launch with networking disabled renders correct fonts.

### 2.3 Stop transmitting hardware device IDs — fixes S5 [sonnet]
- `device_util.dart`: drop `device_info_plus` hardware-ID reads; use the existing persisted UUIDv4 for all platforms (keep reading previously stored IDs so existing installs keep their identity).
- **Acceptance:** `playerJoined` payload contains no OS hardware identifiers; ban list still works across reconnects.

### 2.4 Rewrite + host privacy policy — fixes X1, W3, I6 [sonnet for doc; haiku for in-app link]
- Correct §2 (all four platform key stores), §3 (what's broadcast via NSD), remove claims invalidated until 2.1/2.2 land; add contact email.
- Host at a public URL (GitHub Pages of this repo is fine); add the link to the Credits/About screen.
- **Acceptance:** policy URL live; in-app link opens it; policy statements match observed app behavior.

### 2.5 Rename "Jeopardy" modifiers — fixes X2 [haiku]
- Rename user-facing strings (and ideally internal identifiers) in `guide_screen.dart`, `host_screen.dart`, `solo_summary_screen.dart`, `calibration_screen.dart`, `game_providers.dart`, and `game_engine`. Suggested: "Wildcard" or "High Stakes".
- **Acceptance:** `grep -ri jeopardy` returns nothing user-visible; persisted save data with old mode keys still loads (check persistence enums before renaming serialized keys — if keys are serialized, rename display strings only).

---

## Phase 3 — Security hardening (2–4 days; strongly recommended before launch, not strictly reviewer-visible)

### 3.1 Authenticated transport encryption — fixes S1 [opus]
- Replace `Encrypter(AES(key))` (CTR, unauthenticated) in `crypto_util.dart` and `handshake_manager.dart` with AES-GCM or encrypt-then-HMAC. Version the wire format (`v2:iv:ct:tag`) so mismatched app versions fail with a clear "update required" error instead of garbage.
- Update both transports + tests. **Acceptance:** tampered ciphertext is rejected before JSON parse; all transport tests pass; cross-version mismatch produces the clear error.

### 3.2 Join-handshake replay protection — fixes S2 [opus]
- Host sends a random nonce on socket open; client's `playerJoined` must include it (inside the encrypted payload). Reject joins re-using a live player ID from a different socket.
- **Acceptance:** replayed join ciphertext from a second socket is rejected; test added.

### 3.3 Retire legacy save-key fallback — fixes S4 [sonnet]
- On successful legacy `unpack`, immediately re-`pack` with the master key and persist. Add a version marker; schedule fallback removal one release later. Switch HMAC comparison to constant-time.
- **Acceptance:** legacy save migrates once, then verifies only via master key; migration test added.

### 3.4 Resolve discovery-join UX — fixes S6 [sonnet]
- Decision needed (default: option a): (a) make the discovered-hosts list display-only ("join via host's QR code") and fix the manual-entry hint to include `?secret=`; or (b) design a host-approval join flow (larger, defer post-launch).
- **Acceptance:** no code path attempts a secretless `joinSession`; UX communicates how to join.

### 3.5 Playtest server hardening — fixes S7 [haiku]
- Add payload size cap, basic rate limit, bind default to localhost/LAN interface, strip exception details from responses, simple bearer token for `/api/stats`. Not store-relevant; do whenever convenient.

---

## Phase 4 — Store submission mechanics (paperwork; parallel with Phase 3)

- **Apple (both stores):** privacy nutrition labels ("Data Not Collected" after Phase 2), export-compliance answers, age rating questionnaire (declare user interaction for multiplayer), hosted privacy policy URL, screenshots per device class, app-level `PrivacyInfo.xcprivacy` (I5) [haiku].
- **Microsoft:** Partner Center identity → feed into MSIX config (1.3), IARC age rating, store listing + privacy URL, WACK (Windows App Certification Kit) run on the MSIX.
- **Release pipeline:** ensure `--obfuscate --split-debug-info` on iOS/macOS/Windows release builds (X3) [haiku — CI/script tweak].
- **Final regression:** full multiplayer matrix — macOS(sandboxed) ↔ iOS ↔ Windows(MSIX) host/join combinations, plus offline first-launch on each platform.

---

## Suggested execution order

| Order | Tasks | Agent | Notes |
|---|---|---|---|
| 1 | 1.1, 1.2 | haiku | Pure plist/entitlements edits |
| 2 | 1.3, 1.4 | sonnet | MSIX + platform gating |
| 3 | 2.1, 2.2, 2.3 | sonnet | Privacy-truth trio; independent, can parallelize |
| 4 | 2.4, 2.5 | sonnet/haiku | Policy rewrite + rename |
| 5 | 1.5 + re-test | — | Manual verification under sandbox/MSIX |
| 6 | 3.1, 3.2 | opus | Crypto redesign — single agent, both tasks (shared wire-format decision) |
| 7 | 3.3, 3.4 | sonnet | Persistence migration + join UX |
| 8 | Phase 4 | haiku + manual | Paperwork, pipeline, WACK |

Estimated total: **4–7 working days** of focused effort to a submittable state on all three stores.
