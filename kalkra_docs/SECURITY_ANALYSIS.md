# Kalkra — Security Analysis (Pre-Store-Submission)

**Date:** 2026-07-12
**Scope:** Main Flutter app (`kalkra/`), transport packages, persistence layer, playtest server.
**Context:** Target stores — Mac App Store, iOS App Store, Microsoft Store.

Severity legend: 🔴 High (fix before submission) · 🟡 Medium (fix before or shortly after launch) · 🟢 Low (hygiene).

---

## S1 🔴 Transport encryption is unauthenticated (and not the mode the comments claim)

**Files:** `packages/transport_lan/lib/src/crypto_util.dart:19`, `packages/qr_secure_handshake/lib/src/handshake_manager.dart:46`

`Encrypter(AES(key))` from the `encrypt` package defaults to **SIC/CTR mode**, not CBC as the comment states. Consequences:

- **No integrity/authentication.** CTR ciphertexts are malleable: an attacker on the LAN who knows any plaintext structure (the JSON event format is public — the repo is open source) can flip bits in transit without knowing the key.
- **"Secret is verified by successful decryption" (`lan_host_transport.dart:88`) is false in CTR mode.** CTR decryption never fails — any input "decrypts" to bytes. The only real gate is `jsonDecode` throwing on garbage, which is not an authentication mechanism.

**Fix:** Move to an AEAD construction — AES-GCM (via `cryptography` or `pointycastle`) or encrypt-then-HMAC with the existing `crypto` package. Note: `PersistenceSecurity.pack()` already does encrypt-then-HMAC correctly; the transport layer should match that bar.

## S2 🔴 `playerJoined` replay allows session-slot hijack

**File:** `packages/transport_lan/lib/src/lan_host_transport.dart:65-72, 85-100`

Sequence-number replay protection only applies **after** `currentClientId` is set. The encrypted `playerJoined` message itself is replayable: an attacker who captures one on the LAN can replay it from **their own socket**, and the host will overwrite `_clientMap[player.id]` with the attacker's channel — silently hijacking that player's session (receiving their messages, impersonating them). LAN-scoped, but this is exactly the class of attack the sequence numbers were added for.

**Fix:** Include a per-connection nonce/challenge in the join handshake (host sends a random nonce on socket open; client must echo it inside the encrypted join payload), or reject `playerJoined` for an ID that already has a live channel.

## S3 🔴 Playtest telemetry ships in the production app

**Files:** `kalkra/lib/src/screens/solo_summary_screen.dart:31-34`, `kalkra/lib/src/services/playtest_service.dart:78`

`SoloSummaryScreen` — part of the **main** app flow, not just `playtest_main.dart` — auto-submits player name, mode, difficulty, and score to `http://localhost:8000/api/results` after every solo match on native builds. This:

- Contradicts the privacy policy ("Kalkra does NOT collect, transmit… any personal information").
- Forces a "data collected" answer on Apple's privacy nutrition label and Microsoft's privacy disclosures.
- Is plaintext HTTP (ATS-relevant on Apple platforms).
- Fires a failing network request on every user's machine for no benefit.

**Fix:** Gate submission behind the playtest entry point (compile-time flag or environment define), so store builds contain no result-submission path. This one change makes "Data Not Collected" a truthful nutrition-label answer.

## S4 🟡 Legacy save-file key path permanently defeats tamper protection

**File:** `kalkra/lib/src/services/persistence_security.dart:26-31, 78-89`

`unpack()` falls back forever to a legacy scheme keyed by `deviceId + "KALKRA_VAULT_S01_2026"` — a **hardcoded salt in an open-source repo**. Anyone who knows their own deviceId can forge a valid legacy HMAC and craft arbitrary "vault" contents, so the hardware-backed protection is only as strong as the legacy fallback. The privacy policy's "hardware-backed encryption" claim (§2) is overstated while this path exists.

**Fix:** On successful legacy unpack, immediately re-`pack()` with the master key (migration), and remove the fallback after one release cycle. Also: use a constant-time comparison for HMAC signatures (current `==` string compare at line 71 is not constant-time; low practical risk locally, but free to fix).

## S5 🟡 Raw OS device identifiers are transmitted to LAN peers

**Files:** `kalkra/lib/src/config/device_util.dart:27-39`, `packages/transport_lan/lib/src/lan_client_transport.dart:82`

The raw `identifierForVendor` (iOS), `systemGUID` (macOS — the IOPlatformUUID), and Windows `deviceId` are sent to the multiplayer host inside `playerJoined` for ban-list purposes. Issues:

- The privacy policy (§3) says only Callsign and Elo are shared — deviceId is not disclosed.
- Apple treats device-identifier collection/fingerprinting skeptically (App Review 5.1.1/5.1.2); macOS `systemGUID` may also be unavailable under the App Sandbox.
- A stable hardware GUID broadcast to arbitrary LAN peers is more identifier than a ban list needs.

**Fix:** Send `sha256(installUuid)` — or just the existing per-install UUID fallback — instead of hardware GUIDs. Ban lists work identically. Then remove `device_info_plus` hardware-ID reads entirely (the shared_preferences-cached UUID already provides persistence).

## S6 🟡 Wi-Fi discovery join path is broken and hints at a secretless workflow

**Files:** `kalkra/lib/src/screens/join_screen.dart:180, 217`

Hosts discovered via NSD are joined with a bare `ws://ip:port` URI — but `LanClientTransport.joinSession` throws `Missing encryption secret` (`lan_client_transport.dart:34`). So the discovery list is dead UX, and the manual-entry hint (`ws://192.168.1.5:8080`) teaches users a format that can never work. The README already flags this inconsistency.

**Fix (decide one):** (a) discovery list becomes display-only with "ask host for QR code," or (b) implement a proper join-approval handshake so discovery join works without pre-shared secret. Option (a) is a small change and preserves the security model.

## S7 🟢 Playtest server hardening (not store-shipped; fix before any public exposure)

**File:** `playtest_server/bin/server.dart`

Parameterized SQL is good. Remaining gaps if this ever faces the internet: no auth on `POST /api/results`, no payload size cap, no rate limiting, `GET /api/stats` publicly exposes all player names, error responses leak exception details, binds to `anyIPv4`. Acceptable for a trusted-LAN playtest; do not deploy publicly as-is.

## S8 🟢 NSD TXT record broadcasts callsign and Elo pre-auth

**File:** `packages/transport_lan/lib/src/lan_host_transport.dart:122-130`

Anyone on the LAN sees the host's callsign and Elo without joining. This matches the privacy policy's LAN-sharing disclosure, so it's acceptable — just make sure the policy wording covers "visible to anyone on the network," not only "other players."

---

## Explicitly checked and clean

- **No hardcoded API keys, tokens, or passwords** found in app, packages, or server source (the only embedded constant is the S4 legacy salt).
- **SQL injection:** playtest server uses parameterized queries throughout.
- **Randomness:** all key/secret generation uses `Random.secure()` / `Key.fromSecureRandom` — correct.
- **Rate limiting & heartbeat** on the host transport are real and reasonable (token bucket, 10 cap / 5 per sec).
- **Asset licensing:** all audio is CC0 with attributions maintained in `CREDITS.md` — clean for store IP checks.
- **Bundle IDs** are properly set (`com.overengineeredhobbies.kalkra`) on iOS, macOS, and Android — no `com.example` leftovers.
