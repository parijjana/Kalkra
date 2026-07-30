# Kalkra — iOS App Store Listing (draft)

Draft copy for App Store Connect. Character limits noted in parentheses; all
within Apple's limits and machine-checked with
`store-launch-kit/scripts/validate_listing.py --store ios-app-store`.

Apple uses an **identical field set** for the Mac App Store and the iOS App
Store, so this mirrors `STORE_LISTING_MAC.md`. Only the platform-specific lines
differ — they are marked **[iOS]** below. Keep the two files in sync when
editing shared copy.

---

## App Name (30)
**Kalkra** (6)

## Subtitle (30) — pick one
- `Mental math, reimagined` (23) ← recommended
- `The target number game` (22)
- `Six numbers. One target.` (24)

## Promotional Text (170) — editable anytime without review
> Six numbers, one target, endless ways to get there. Sharpen your mental math
> with fast, addictive number puzzles. Fully offline — no accounts, no ads, no
> tracking. (163)

*(The Mac file's variant of this line is **169/170** — it fits, but with one
character to spare. This wording says the same thing with 7 characters of
headroom. Note `—` is one character, and Apple counts the whole string.)*

## Keywords (100, comma-separated, no spaces) — pick one line
- `mental math,math game,numbers,puzzle,brain training,arithmetic,target,countdown,logic,offline` (93) ← recommended
- `math,numbers game,mental arithmetic,brain,puzzle,logic,target number,countdown,training,solo` (92)

*(Don't repeat words already in the app name/subtitle — Apple indexes those
separately. Don't include device names like "iPhone"/"iPad"; Apple ignores them
and they waste the budget.)*

---

## Description (4000)

**Kalkra is a fast, elegant mental-math game built around one simple, endlessly
replayable idea: reach the target.**

You're given a small pool of numbers and the four operators — +, −, ×, ÷.
Combine them to hit the target number. Each number can be used once. Sounds
simple. Then the timer starts, the targets multiply, and the operators start
disappearing.

Every round is generated fresh and verified solvable before you ever see it, so
you're never stuck on an impossible puzzle — only on how fast your brain can
find the path.

**GAME MODES**
• Practice — one target, six numbers, no pressure. Learn the ropes.
• Endless — starts gentle and ramps up forever. How long can you last?
• Progressive — a ladder of twists: forbidden numbers, two targets at once,
  expanding pools, mandatory numbers, and sudden countdowns.
• Tunnel Vision — one target stays fixed while the numbers refresh every round.
• Permutations — multiple solutions welcome; find as many paths as you can.
• Powers of 2 — a specialized pool and target type for binary brains.
• Triple Threat & Double Danger — juggle multiple targets in a single round.

**WILDCARD MODIFIERS**
Speed pressure, operator lockouts, and double-or-nothing scoring drop in to keep
you honest.

**BUILT TO COME BACK TO**
• A full career with stats, an Elo skill rating, and unlockable achievements.
• Multiple hand-crafted visual themes to make it yours.
• **[iOS]** One responsive design that adapts to the device: a focused portrait
  layout on iPhone, and the full roomy layout in landscape on iPad — including
  Split View, where it switches layouts as you resize.

**PRIVACY BY DESIGN**
Kalkra is completely offline. No account. No sign-up. No ads. No in-app
purchases. No analytics, no tracking, no data ever leaves your device. Just you
and the numbers.

Whether you've got two minutes or twenty, Kalkra turns mental math into
something you'll actually want to keep playing.

---

## What's New (4000) — for v1.0
> First release of Kalkra. Reach the target, climb your career, and see how
> sharp your mental math really is.

---

## Other App Store Connect fields (for reference — you fill these)
- **Category:** Games → Puzzle (primary). Optional secondary: Education.
- **Age rating:** expected 4+ (no objectionable content, no user-generated
  content, no web access in the app).
- **Support URL:** https://overengineeredhobbies.dev/projects/kalkra_support
- **Marketing URL (optional):** https://overengineeredhobbies.dev/demos/kalkra/
- **Privacy Policy URL:** https://overengineeredhobbies.dev/projects/kalkra_privacy
- **App Privacy questionnaire:** "Data Not Collected" (offline, no telemetry in
  store builds).
- **Price:** TBD
- **Copyright:** 2026 Animesh Sarkar (Overengineered Hobbies)

### **[iOS]** Platform-specific notes
- **Bundle ID:** `com.overengineeredhobbies.kalkra` — the SAME id as the macOS
  build, so both platforms live under one App Store Connect app record. Build
  numbers are unique **per platform**, so iOS may reuse `1.0.0 (1)` even though
  the macOS `1.0.0 (1)` is already submitted. No version bump is required.
- **Device support:** iPhone and iPad. Orientation is enforced in code by
  `main.dart` `_applyOrientationLock()` — phones (`shortestSide < 600`) are
  locked to portrait; tablets allow all four orientations. `Info.plist` permits
  landscape on both.
- **Screenshots:** iPhone 6.9" 1290×2796 (portrait) and iPad Pro 13"
  2732×2048 (**landscape**) — 8 scenes each, in
  `kalkra/store_screenshots/ios/{iphone69,ipad13}/`.
- **Encryption / export compliance:** no encryption beyond Apple-exempt
  platform crypto. Saves use an HMAC for tamper detection, which falls under the
  standard exemption; answer the export-compliance question accordingly. Setting
  `ITSAppUsesNonExemptEncryption=false` in `Info.plist` avoids being asked per
  build.
- **No ads, no IAP, no accounts, no network calls** in store builds — the
  multiplayer transport packages are not compiled in.

---

*Draft — review and adjust tone/claims before submitting. Verify mode names
against the shipped build.*
