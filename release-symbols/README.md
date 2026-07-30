# release-symbols/ — de-obfuscation maps for shipped builds

**The files in this directory are deliberately NOT in git. Do not commit them,
and do not attach them to a public GitHub Release.** Only this README is tracked.

## What these files are

Kalkra's store builds are compiled with `--obfuscate --split-debug-info`, which
strips Dart class and function names from the shipped binary. Each build emits a
companion symbol map (a Mach-O dSYM companion, e.g. `app.ios-arm64.symbols`)
containing the mapping back to the original names.

Layout — one directory per platform and version+build, so a crash report can be
matched to the exact binary it came from:

```
release-symbols/
  ios/1.0.0+1/app.ios-arm64.symbols
              SHA256SUMS.txt
```

## Why they must be kept

A symbol map is the **only** way to read a crash report from its build. Kalkra
ships no crash reporting or analytics of any kind (it is fully offline), so the
only crash data available is what Apple/Google surface in App Store Connect /
Play Console — and those reports arrive obfuscated. Without the matching map
they are permanently unreadable.

The maps are emitted into `kalkra/build/`, which is git-ignored **and wiped by
`flutter clean`**. Moving each one here immediately after a release build is what
stops it being lost.

## Why they must stay private (this repo is public)

Verified by inspecting `ios/1.0.0+1/app.ios-arm64.symbols`:

- **It contains the complete original Dart symbol set** — `SolverEngine`,
  `MatchManager`, `CareerManager`, `RoundManager`, `KalkraApp` and the rest, i.e.
  exactly the names obfuscation removed from the shipped app. Publishing it
  hands back everything `--obfuscate` was there to withhold, including the
  save-integrity/HMAC and native-bridge internals that
  `PRODUCTION_ROADMAP.md` lists under Security Hardening.
- **It embeds local build paths** — ~924 references to `/Users/<username>/...`
  (`~/.pub-cache/hosted`, the project checkout path), which leak the build
  machine's account name and directory layout.

What it does **not** contain — checked explicitly, all zero hits: the Apple Team
ID, signing certificate names ("Apple Distribution"/"Apple Development"),
provisioning profiles, `.p12` bundles, private keys, or API keys. **Nothing tied
to the Apple ID is in here.** The risk is de-obfuscation and local-path leakage,
not credential exposure.

## Recommended handling

1. Keep this working copy (ignored by git) for day-to-day use.
2. Keep a second copy somewhere private and durable — a private repo, or
   encrypted cloud/offline storage. Do not rely on this directory alone; it is
   untracked, so nothing restores it if the machine is lost.
3. Verify integrity with `shasum -a 256 -c SHA256SUMS.txt`.
4. Never delete an old version's map while that version is still installed on
   any user's device — crash reports can arrive long after release.

## Adding a new build's map

```bash
# after: flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
V=1.0.1+2                      # match pubspec.yaml version+build
mkdir -p release-symbols/ios/$V
mv kalkra/build/debug-info/*.symbols release-symbols/ios/$V/
( cd release-symbols/ios/$V && shasum -a 256 *.symbols > SHA256SUMS.txt )
```

Android AAB builds emit their own map the same way — file those under
`release-symbols/android/<version+build>/`.

## De-obfuscating a crash report

```bash
flutter symbolize -i <crash.txt> -d release-symbols/ios/1.0.0+1/app.ios-arm64.symbols
```

The map must be the one from the **exact** build the report came from; a map from
a different build produces wrong or missing frames.
