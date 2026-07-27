# Kalkra — screenshot layout overflow issues

**Status:** RESOLVED 2026-07-27. All 10 overflows fixed across 6 source files;
re-captured and re-validated → `SCREENSHOTS: PASS` (48/48 dims `[OK]`, 0
`[OVERFLOW]`). Found earlier the same day by the store-launch-kit
screenshot-validation pipeline. Fixes (uncommitted on `chore/store-screenshots`):
- `account_screen.dart` `_ThemeCard` — theme-name `Text` → `Flexible`+ellipsis (30px+16px right)
- `stats_screen.dart:253` — mobile `childAspectRatio` 1.1 → 0.95 (7px bottom ×4)
- `achievements_screen.dart:158` — mobile `childAspectRatio` 4.0 → 3.5 (10px bottom ×7)
- `match_setup_screen.dart` — right column body → `Expanded`+`SingleChildScrollView`, dropped `Spacer` (24px bottom)
- `game_screen.dart` `_buildGameCockpit` — bottom stack wrapped in `FittedBox(scaleDown)` (29px bottom)
- `top_nav_bar.dart:58` — brand→tabs gap 80 → 76; single edit clearing all 5 ipad-13 1.2px-right subpixel flags

The original findings below are kept for reference.

**Scope note:** These overflows appear only in the **Microsoft / iOS / Play**
screenshot targets. The **Mac** shots are clean, so this does **not** block the
Mac-first App Store submission — fix before the Microsoft/iOS/Play submissions.

---

## How these were found / how to reproduce

The in-app capture harness (`lib/screenshot_main.dart`, untracked) now installs a
`FlutterError.onError` hook that flags any RenderFlex `overflowed` error against the
exact shot being rendered, and writes the result into `store_screenshots/capture_manifest.json`.
The validator then fails on any flagged shot.

Repro (macOS, debug — overflow errors only paint/report in debug):

```bash
cd ~/code/projects/Kalkra/kalkra

# Kalkra enforces the macOS sandbox in TWO places; both must be OFF to let the
# harness write PNGs to the repo path (the sandbox container is TCC-blocked from
# host reads). These two files are git-tracked — REVERT them after.
#   macos/Runner/DebugProfile.entitlements   -> com.apple.security.app-sandbox = false
#   macos/Runner.xcodeproj/project.pbxproj   -> ENABLE_APP_SANDBOX = NO (all configs)

flutter run -d macos -t lib/screenshot_main.dart      # writes store_screenshots/ + capture_manifest.json

git checkout -- macos/Runner/DebugProfile.entitlements macos/Runner.xcodeproj/project.pbxproj   # MANDATORY revert

python3 ~/code/projects/store-launch-kit/scripts/validate_screenshots.py \
    ~/code/projects/Kalkra/kalkra/store_screenshots      # -> SCREENSHOTS: PASS|FAIL
```

`capture_manifest.json` records `overflow` + `overflow_details` per shot — the
authoritative list of what to fix.

---

## The 10 overflows

Ordered worst → trivial. Same 8 scenes render on every target; a scene overflows
on the narrower targets, so the fix is in the scene's own layout (make it
fit/scroll at the smallest logical size, not per-target hacks).

| # | Scene / screen | Overflowing target(s) | Amount | Notes |
|---|---|---|---|---|
| 1 | `06-account` | play/phone (360×800) | **30px + 16px right** | Worst. Account screen row(s) too wide for narrow phone. |
| 2 | `08-game` | microsoft (1280×720) | **29px bottom** | Game screen too tall for 16:9 desktop logical height. |
| 3 | `02-mode-select` | microsoft (1280×720) | **24px bottom** | Root cause located: **`Column` at `lib/src/screens/match_setup_screen.dart:152`**. |
| 4 | `07-achievements` | play/phone (360×800) | **10px bottom** (recurring) | Achievements list/grid too tall on narrow phone. |
| 5 | `05-stats` | play/phone (360×800) | **7px bottom** (recurring) | Stats screen too tall on narrow phone. |
| 6–10 | `01-dashboard`, `02-mode-select`, `05-stats`, `06-account`, `07-achievements` | ios/ipad13 (2048×2732 → logical 1024×1366) | **~1.2px right** each | Almost certainly subpixel rounding, not a real layout break. Lowest priority; may resolve incidentally or need a 1–2px width/padding tweak. |

Only the `02-mode-select` overflow produced a full stack trace before Flutter
throttled the rest to "Another exception was thrown", so the other file locations
still need to be traced (find the scene's screen widget; the scene→screen mapping
is in `_buildScene` / `_sceneNames` in `lib/screenshot_main.dart`).

---

## Fix policy & acceptance criteria

- **Policy:** locate → propose the layout fix → human confirms → apply → re-capture
  → re-validate. The harness/validator never edit app code.
- **Suggested order:** #1–#5 first (real squeezes on phone/desktop). Re-evaluate
  #6–#10 (ipad13 ~1.2px) after — they may clear on their own.
- **Prefer** fixing each *scene's own* layout to fit/scroll at the smallest logical
  size, rather than target-specific branches.
- **Done when:** re-running the repro above yields `SCREENSHOTS: PASS` (0 `[OVERFLOW]`),
  with dims still all `[OK]`.

## Not in scope here
Committing anything, and the separate deferred multiplayer "coming soon" content
fix (see the release plan). This log is only the overflow debt.
