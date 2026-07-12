# Kalkra — Store Policy & Compliance Analysis

**Date:** 2026-07-12
**Targets:** Mac App Store, iOS App Store, Microsoft Store.

Severity legend: 🔴 Guaranteed rejection / crash in review · 🟡 Likely reviewer flag or policy exposure · 🟢 Required paperwork/metadata.

---

## Mac App Store

### M1 🔴 App Sandbox is disabled — automatic rejection
`macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` both set `com.apple.security.app-sandbox` to **false**. The Mac App Store has required sandboxing since 2012; this is an instant rejection. Release.entitlements also contains **no network entitlements**, so once sandboxing is enabled, LAN hosting/joining will break unless these are added:

- `com.apple.security.app-sandbox` → true
- `com.apple.security.network.server` → true (hosting the WebSocket lobby)
- `com.apple.security.network.client` → true (joining, NSD, font/HTTP if any remain)
- `com.apple.security.device.camera` → true (QR scanning via mobile_scanner)

The app must then be **re-tested under the sandbox** — NSD registration, WebSocket serve on `anyIPv4`, secure storage (Keychain), and `systemGUID` reads all behave differently sandboxed. "Tested on Mac" without the sandbox is not tested for the Mac App Store.

### M2 🔴 Missing privacy usage descriptions (macOS Info.plist)
`macos/Runner/Info.plist` has no usage strings. Required:
- `NSCameraUsageDescription` — QR scanner (camera access without it = crash/silent failure + rejection)
- `NSLocalNetworkUsageDescription` — macOS 15 Sequoia now shows the local-network consent prompt like iOS
- `NSBonjourServices` → `_kalkra._tcp` — required for NSD browse

### M3 🟢 Export compliance
The app uses AES (transport + save files). App Store Connect will ask encryption questions; add `ITSAppUsesNonExemptEncryption` to Info.plist (standard-algorithm usage generally qualifies as exempt/mass-market, but it must be declared, and a French declaration may apply). Same answer set applies to iOS.

### M4 🟡 Hardened runtime / signing pipeline
`com.apple.security.cs.allow-jit` is set in DebugProfile (fine for debug). Verify the Release build ships without JIT/debug entitlements and with correct signing for MAS distribution.

---

## iOS App Store

### I1 🔴 Missing `NSCameraUsageDescription` — hard crash in review
`ios/Runner/Info.plist` has no camera usage string. Opening the Join screen (which unconditionally renders `MobileScanner`) will **crash the app instantly** on iOS. App Review exercises multiplayer screens; this is a guaranteed 2.1 (App Completeness) rejection.

### I2 🔴 Missing local-network keys — multiplayer silently dead on iOS 14+
Without `NSLocalNetworkUsageDescription` and `NSBonjourServices` (`_kalkra._tcp`), NSD browsing/registration and peer WebSocket connections fail. Reviewers who try multiplayer will see a non-functional feature (2.1 rejection); a missing purpose string for a used API is itself a rejection.

### I3 🟡 Privacy nutrition labels must match actual behavior
As the code stands today, truthfully the label would need to declare: **Name** (callsign sent to playtest server), **Device ID** (hardware IDs sent to LAN hosts), **Gameplay content** (scores to playtest server). After fixes S3 + S5 (see SECURITY_ANALYSIS.md) the truthful answer becomes **"Data Not Collected"** — dramatically better for review and marketing. Do the fixes first, then fill the label.

### I4 🟡 Google Fonts fetches fonts from Google servers at runtime
`google_fonts` (used across `app_theme.dart`) downloads fonts from `fonts.gstatic.com` on first run unless bundled. This (a) contradicts privacy policy §4/§5 ("no third-party trackers… no data sent to external servers" — a runtime request discloses user IPs to Google), (b) breaks the all-offline claim, and (c) means first launch on a network-restricted device shows fallback fonts. Fix: download the font files, declare them in `pubspec.yaml` assets, set `GoogleFonts.config.allowRuntimeFetching = false`. (Font licenses are OFL — bundling is fine; keep the license notice.)

### I5 🟢 Privacy manifest (`PrivacyInfo.xcprivacy`)
Required-reason APIs (UserDefaults via shared_preferences, etc.) are covered by plugin-supplied manifests in current Flutter, but add an app-level `PrivacyInfo.xcprivacy` declaring no tracking / no collected data types once S3/S5 are fixed. Cheap insurance against automated rejection emails.

### I6 🟢 Paperwork
- Privacy policy must be hosted at a public URL (App Store Connect requires it; the in-repo `PRIVACY_POLICY.md` is not enough).
- Age rating questionnaire: note that LAN multiplayer with free-text callsigns counts as "user interaction" and callsign display as user-generated content.
- Do **not** opt into the Kids category — "educational math game for all ages" is fine as a general-audience 4+/9+ app; Kids category adds heavy extra requirements.

---

## Microsoft Store

### W1 🔴 `mobile_scanner` does not support Windows — Join screen will crash
The package declares android/ios/macos/web only. `join_screen.dart:197` renders `MobileScanner` unconditionally, so opening the Join screen on Windows throws (`MissingPluginException`). Store certification testers exercising multiplayer will fail the app (Policy 10.1.1 — app must not crash). Fix: platform-gate the scanner (show it only where supported; Windows gets manual entry + discovery list). Note "tested on Windows" likely didn't cover the Join screen.

### W2 🔴 No MSIX packaging configuration
Microsoft Store submission requires an MSIX package. There is no `msix` configuration in `pubspec.yaml`. Needed: `msix` dev dependency plus config — identity name / publisher (from Partner Center), display name, logo, and **capabilities**: `internetClient`, `internetClientServer`, `privateNetworkClientServer` (LAN hosting + NSD). Without `privateNetworkClientServer`, the WebSocket host and discovery won't work in the packaged app. Re-test LAN play **from the installed MSIX**, not the loose exe — AppContainer network rules differ (loopback is also restricted, which incidentally hides the S3 playtest localhost call — another reason to remove it).

### W3 🟡 Privacy policy link requirement
Store Policy 10.5.1: any app that accesses the network must have a privacy policy link in both the store listing and **inside the app** (settings/about screen). The Credits screen should link to the hosted policy URL.

### W4 🟢 Paperwork
- Age ratings via IARC questionnaire in Partner Center (declare user interaction in multiplayer).
- `nsd`, `network_info_plus`, `flutter_secure_storage`, `window_manager` all support Windows — verified, no blockers there.

---

## Cross-store issues

### X1 🟡 Privacy policy is inaccurate as written
`PRIVACY_POLICY.md` needs corrections before hosting:
- "does NOT collect, transmit" — false until playtest telemetry (S3) and Google Fonts runtime fetch (I4) are removed/fixed.
- §2 mentions only "Android Keystore / iOS Keychain" — add macOS Keychain and Windows credential storage (flutter_secure_storage backends actually in use).
- §3 says only Callsign and Elo are shared on LAN — deviceId is also sent today (S5); either fix the code (preferred) or the policy.
- Callsign + Elo are visible to **anyone on the network** via NSD broadcast, not just match participants — say so.
- Add a contact email (all three stores expect a support/privacy contact).

### X2 🟡 "Jeopardy" mode naming — trademark exposure
"Jeopardy modifiers" appears in UI-facing code (`guide_screen.dart`, `host_screen.dart`, etc.). JEOPARDY! is a famous, actively-enforced trademark (Sony/Jeopardy Productions). Apple 5.2.1 (third-party IP) and Microsoft 10.7 both allow takedown/rejection on this. Rename user-visible text to something like "Wildcard", "High Stakes", or "Gamble" modifiers. (The Countdown-style numbers mechanic itself is fine — game rules aren't protectable — just avoid the word "Countdown" in store marketing copy.)

### X3 🟢 Store listing consistency
- `CFBundleDisplayName` is currently "Kalkra App" on iOS — should be just "Kalkra".
- Ensure obfuscation (`--obfuscate --split-debug-info`) is applied to iOS/macOS/Windows release builds per `GEMINI.md` mandate — the roadmap only marks AAB/IPA.
- Screenshots, descriptions, and support URL per store; the existing `screenshots/` folder is a start.
