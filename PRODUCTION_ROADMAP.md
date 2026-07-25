# KALKRA Production & Play Store Roadmap

This document tracks the final requirements for a public Play Store release.

## 🔒 Security Hardening (Current Focus)
- [x] **Obfuscation Mandate:** All production builds (AAB/IPA) must use `--obfuscate --split-debug-info`.
- [x] **Save Integrity:** Plaintext + HMAC (master key in `flutter_secure_storage`); AES dropped so key loss can't destroy saves.
- [x] **HMAC Validation:** Implement tampering detection for all local save files.
- [ ] **R8 Scrambling:** Tighten `proguard-rules.pro` for Android native bridge protection.

## 🎨 Visual & UX Polish (Post-Music)
- [ ] **Adaptive Icons:** Generate full MIPMAP set using `flutter_launcher_icons`.
- [ ] **Splash Screen:** Implement branded native splash using `flutter_native_splash`.
- [ ] **App Bundle (AAB):** Configure signing keys and build optimization.
- [ ] **Store Listing Assets:**
    - Feature Graphic (1024x500)
    - High-res screenshots (8+)
    - Promotional video

## ⚖️ Legal & Compliance
- [x] **Privacy Policy:** Live at https://overengineeredhobbies.dev/projects/kalkra_privacy.
- [x] **Privacy Policy Link:** Added to `CreditsScreen` (external link active).
- [ ] **Terms of Service Link:** Pending; awaiting ToS content creation.
- [ ] **Data Safety Form:** Complete the Google Play Data Safety questionnaire based on local storage usage.

---
*Note: This roadmap is a living document and will be updated as we clear security milestones.*
