// Standalone MULTI-STORE screenshot-capture entry point.
//
// Renders a curated set of app screens off-screen (inside the running Flutter
// engine, never on the real screen) and rasterizes each one via
// `RenderRepaintBoundary.toImage`, saving store-spec PNGs for every target
// device (Mac App Store, Microsoft Store, iOS iPhone/iPad, Google Play
// phone/tablet). Extended from the original Mac-only harness by store-launch-kit.
//
// Because this captures pixels straight from the widget tree's own compositor
// layer, it needs NO macOS Screen Recording permission -- it never touches the
// system screen-capture APIs at all. It always runs on macOS and forces each
// target's logical size + pixelRatio via MediaQuery, so a single run produces
// the iOS/Android phone & tablet sizes too.
//
// Run with:
//   flutter run -d macos -t lib/screenshot_main.dart
//
// NOTE: writes to an absolute path inside the repo (see [_outRoot]). This works
// with the App Sandbox left ENABLED — DebugProfile.entitlements grants a
// debug-only `temporary-exception.files.absolute-path.read-write` for that path
// (plus `network.server`, without which the sandbox blocks the Dart VM service
// socket and `flutter run` cannot attach). Nothing needs toggling or reverting.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'src/providers/providers.dart';
import 'src/screens/account_screen.dart';
import 'src/screens/achievements_screen.dart';
import 'src/screens/game_screen.dart';
import 'src/screens/main_screen.dart';
import 'src/screens/match_setup_screen.dart';
import 'src/screens/results_screen.dart';
import 'src/screens/solo_summary_screen.dart';
import 'src/screens/stats_screen.dart';
import 'src/services/sound_service.dart';
import 'src/theme/app_theme.dart';

/// Absolute output root inside the repo. Per-store subfolders are created under
/// it. Kalkra ships with the App Sandbox ON (entitlement + `ENABLE_APP_SANDBOX=YES`),
/// and a sandboxed app can normally only write inside its own container. Rather
/// than disabling the sandbox per run, DebugProfile.entitlements grants a
/// DEBUG-ONLY absolute-path exception for exactly this directory — so this path
/// must stay in sync with that entitlement. Release.entitlements has no such key,
/// so store builds are unaffected. The run prints `SCREENSHOTS_WRITTEN_TO:`.
const String _outRoot =
    '/Users/animeshsarkar/code/projects/Kalkra/kalkra/store_screenshots';

/// Theme used for every hero shot.
const AppThemeType _heroTheme = AppThemeType.vectorPop;

/// How long `_settle()` will wait for a screen to stop animating before giving
/// up and rasterizing anyway. Comfortably clears the longest entrance animation
/// in the app (GameScreen's 800ms controller) with room for slow frames.
const Duration _settleTimeout = Duration(seconds: 4);

/// Consecutive animation-free frames `_settle()` requires before it calls the
/// tree settled.
const int _quietFramesRequired = 3;

/// Longest a single `endOfFrame` await may block before `_settle()` gives up on
/// that frame. macOS stops producing frames for an occluded window or a sleeping
/// display, and an un-timed-out `await endOfFrame` then hangs the whole capture
/// run forever — [_settleTimeout] cannot save it, because a deadline between
/// awaits is never reached while one await is blocked.
const Duration _frameWaitTimeout = Duration(milliseconds: 500);

// ---------------------------------------------------------------------------
// LAYOUT-ERROR ATTRIBUTION (harness-side, framework ground truth).
//
// A single FlutterError.onError hook (installed in main()) records layout errors
// against the shot being rendered RIGHT NOW. `_currentShotId` is set BEFORE
// setState for each shot, so errors thrown during the build / _settle()
// layout+paint pass attribute to the correct shot. Each shot's lists are folded
// into its capture_manifest.json entry.
//
// TWO buckets, because they fail differently:
//   _overflowByShot     — 'overflowed': content too big for its box, but it
//                         still PAINTS. Visible as clipped/striped content.
//   _layoutErrorsByShot — layout ASSERTION failures ([_layoutErrorNeedles]):
//                         the subtree never gets a size, so it paints NOTHING.
//                         This is strictly worse and used to be invisible here:
//                         a hook watching only 'overflowed' let four blank-cockpit
//                         gameplay shots through with correct pixel dimensions,
//                         and the validator passed them. See
//                         lessons_learnt/flutter-fittedbox-infinite-width-blank-subtree.md
//
// DEBUG-ONLY: Flutter only routes these through FlutterError.onError when
// assertions are on. NEVER capture with --release/--profile or they go silently
// undetected.
// ---------------------------------------------------------------------------
final Map<String, List<String>> _overflowByShot = <String, List<String>>{};
final Map<String, List<String>> _layoutErrorsByShot = <String, List<String>>{};

/// Substrings identifying a layout failure that leaves a subtree unpainted.
const List<String> _layoutErrorNeedles = [
  'forces an infinite', // BoxConstraints forces an infinite width/height
  'was not laid out', // RenderBox was not laid out
  'hasSize', // 'child!.hasSize': is not true
  'Failed assertion', // any other rendering-library assertion
];

String _currentShotId = '';

/// One store/device output target. Mirrors store-launch-kit's
/// references/store-fields.json `screenshot_targets`: store pixels = w*ratio.
/// [store]/[device] must match a store-fields.json target so the validator's
/// cross-check resolves (px_w/px_h == w*ratio / h*ratio).
class _Target {
  final String store; // store id, matches store-fields.json (e.g. 'ios-app-store')
  final String device; // device id, matches store-fields.json (e.g. 'ipad-13')
  final String dir; // output subfolder under _outRoot; may be nested (e.g. 'ios/ipad13')
  final double w, h, ratio; // logical size + pixelRatio
  final List<String> scenes; // scene names to render for this target
  const _Target(
      this.store, this.device, this.dir, this.w, this.h, this.ratio, this.scenes);
}

/// Scene -> the widget type that must be MOUNTED inside the capture boundary for
/// that scene. The capture loop verifies this after settling, so it photographs
/// the screen it asked for rather than assuming setState + settle got there.
///
/// This exists because a capture run once wrote MISSION CONTROL (the *previous*
/// scene) into play/tablet/03-results.png. ResultsScreen carries a
/// `ref.listen(matchStatusProvider)` that can navigate away, and a stale layer
/// can end up rasterized; the shot had perfect dimensions, no overflow and no
/// layout error, so every other gate passed it. Only a human comparing 48 images
/// caught it, and it did not reproduce on the next run.
///
/// The oracle is a walk of the live element tree, NOT `currentScreenIdProvider`.
/// That provider was tried first and is unusable here: it sticks at
/// 'SoloSummaryScreen' from the solo-summary scene onward even while the correct
/// screens demonstrably mount and paint, so it false-positived 39 of 48 shots.
/// The element tree is ground truth — if the widget is mounted under the capture
/// boundary, it is what gets rasterized.
const Map<String, String> _expectedWidget = {
  'dashboard': 'MainScreen',
  'mode-select': 'MatchSetupScreen',
  'results': 'ResultsScreen',
  'solo-summary': 'SoloSummaryScreen',
  'stats': 'StatsScreen',
  'account': 'AccountScreen',
  'achievements': 'AchievementsScreen',
  'game': 'GameScreen',
};

// Every scene, in dependency order (some shots seed state the next one reads).
const List<String> _allScenes = [
  'dashboard',
  'mode-select',
  'results',
  'solo-summary',
  'stats',
  'account',
  'achievements',
  'game',
];

// One row per screenshot_targets entry in store-fields.json. Mac/Microsoft are
// single-device stores → flat, prefix-free subfolders. iOS/Play are multi-device
// → device subfolders (ios/iphone69, ios/ipad13, play/phone, play/tablet) so no
// filename prefix is needed. Every target renders the full 8-scene set.
//
// ORIENTATION. PHONES are portrait-only: main.dart's _applyOrientationLock()
// pins shortestSide < 600 to portraitUp/Down. TABLETS get all four orientations,
// so they are captured LANDSCAPE — that is the intended default presentation and
// it clears ResponsiveLayout's 1024dp isDesktop breakpoint, giving the roomy
// desktop-style layout instead of a phone layout stretched up a tall canvas.
// (Portrait tablet at 800-1024dp logical width fell under that breakpoint, which
// is why those shots looked like blown-up phone UI with large empty bands.)
// A tablet resized/split-screened below 1024dp still gets the narrow layout at
// runtime — ResponsiveLayout keys off MediaQuery width, so that adapts for free.
//
//        store               device                dir              w     h     ratio  scenes
const List<_Target> _targets = [
  _Target('mac-app-store',   'mac',               'mac',          1440,  900, 2.0, _allScenes),
  _Target('microsoft-store', 'desktop',           'microsoft',    1280,  720, 2.0, _allScenes),
  // App Store Connect has SEPARATE iPhone slots and will not scale between them:
  // uploading a 6.9" shot into the 6.5" slot is rejected outright. 6.5" accepts
  // 1242x2688 or 1284x2778; we render the latter natively (428x926 @3.0) rather
  // than resampling the 6.9" set, whose aspect ratio differs (0.4614 vs 0.4622).
  _Target('ios-app-store',   'iphone-6.9',        'ios/iphone69',  430,  932, 3.0, _allScenes),
  _Target('ios-app-store',   'iphone-6.5',        'ios/iphone65',  428,  926, 3.0, _allScenes),
  _Target('ios-app-store',   'ipad-13-landscape', 'ios/ipad13',   1366, 1024, 2.0, _allScenes),
  _Target('google-play',     'phone',             'play/phone',    360,  800, 3.0, _allScenes),
  _Target('google-play',     'tablet-landscape',  'play/tablet',  1280,  800, 2.0, _allScenes),
];

/// A realistic, experienced-player career so the dashboard and stats screens
/// show real numbers instead of zeros / "Guest" during capture.
final _seededCareer = CareerManager(
  playerName: 'ACE',
  elo: 1480,
  matchesWon: 38,
  matchesPlayed: 54,
  avgSpeedSeconds: 3.8,
  avgAccuracy: 1.2,
  roundsTracked: 240,
  currentStreak: 5,
  bestStreak: 14,
  soundEnabled: true,
  musicEnabled: true,
  rivals: [
    RivalInfo(name: 'Endless', eloShift: 18, date: DateTime(2026, 7, 25, 20, 14), wasSolo: true),
    RivalInfo(name: 'Triple Threat', eloShift: 24, date: DateTime(2026, 7, 25, 18, 47), wasSolo: true),
    RivalInfo(name: 'Progressive', eloShift: 12, date: DateTime(2026, 7, 24, 22, 3), wasSolo: true),
    RivalInfo(name: 'Classic', eloShift: -6, date: DateTime(2026, 7, 24, 19, 21), wasSolo: true),
    RivalInfo(name: 'Tunnel Vision', eloShift: 9, date: DateTime(2026, 7, 23, 21, 38), wasSolo: true),
    RivalInfo(name: 'Double Danger', eloShift: 15, date: DateTime(2026, 7, 23, 8, 55), wasSolo: true),
  ],
);

/// Serves [_seededCareer] in place of the persisted career for every screen
/// that reads [careerProvider] during capture.
class _SeededCareerNotifier extends CareerNotifier {
  @override
  Future<CareerManager> build() async => _seededCareer;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Overflow hook (debug-only): attribute any layout error containing
  // 'overflowed' to the shot rendering now (_currentShotId), then still present
  // it normally so it shows in the console. Flutter only routes these through
  // FlutterError.onError when assertions are on — never capture in release/profile.
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    final first = msg.split('\n').first.trim();
    if (msg.contains('overflowed')) {
      (_overflowByShot[_currentShotId] ??= <String>[]).add(first);
    } else if (_layoutErrorNeedles.any(msg.contains)) {
      // Cap the list: one broken subtree can throw the same assertion on every
      // pumped frame, and an unbounded list would bloat the manifest.
      final bucket = _layoutErrorsByShot[_currentShotId] ??= <String>[];
      if (bucket.length < 10 && !bucket.contains(first)) bucket.add(first);
    }
    FlutterError.presentError(details);
  };

  // Never make sound while capturing.
  SoundService().setMusicEnabled(false);
  SoundService().setSoundEnabled(false);

  if (!kIsWeb && Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      // Just needs to be >= the largest logical target so nothing is clipped
      // before the off-screen raster (which uses OverflowBox) is taken.
      size: Size(1520, 1440),
      center: true,
      title: 'KALKRA — Screenshot Capture',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) => Future.value('test-device')),
        careerProvider.overrideWith(() => _SeededCareerNotifier()),
      ],
      child: const _ScreenshotCaptureApp(),
    ),
  );
}

class _ScreenshotCaptureApp extends ConsumerStatefulWidget {
  const _ScreenshotCaptureApp();

  @override
  ConsumerState<_ScreenshotCaptureApp> createState() =>
      _ScreenshotCaptureAppState();
}

class _ScreenshotCaptureAppState extends ConsumerState<_ScreenshotCaptureApp> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<String> _writtenFiles = [];
  final List<String> _skipped = [];
  /// Shots whose tree never reached visual rest within [_settleTimeout] — each
  /// one may have been rasterized mid-animation, so it needs a human look.
  final List<String> _settleTimeouts = [];
  /// Shots that landed on the wrong screen and recovered on the retry.
  /// Informational: the written PNG is correct, but the flake is real.
  final List<String> _sceneRetries = [];
  /// Shots still on the wrong screen AFTER the retry — the PNG shows a different
  /// screen than its filename claims. A validator failure.
  final List<String> _sceneMismatches = [];
  final List<Map<String, dynamic>> _manifestShots = []; // one entry per written PNG

  bool _started = false;
  Widget? _currentScreen;
  String _shotId = '';
  _Target _target = _targets.first;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runCaptureLoop());
    }
  }

  /// Returns the builder for a named scene. Keeping this a lookup (rather than a
  /// prebuilt list) lets each (target, scene) rebuild fresh state per shot.
  Widget Function(WidgetRef ref) _builderFor(String scene) {
    switch (scene) {
      case 'dashboard':
        return (ref) {
          ref.read(matchProvider).value = null;
          return const MainScreen();
        };
      case 'mode-select':
        return (ref) => const MatchSetupScreen(mode: MatchSetupMode.solo);
      case 'results':
        return (ref) {
          final round = ref.read(roundProvider);
          round.startRoundWithData(numbers: [75, 7, 10, 2, 5, 1], targets: [542]);
          round.setBestSolution(SolverEngine().solve([75, 7, 10, 2, 5, 1], 542));
          round.endRound();
          final session = ref.read(sessionProvider);
          session.addPlayer('solo', 'Player');
          session.recordSubmission('solo', '(75 * 7) + 10', 85);
          return const ResultsScreen(
            playerExpression: '(75 * 7) + 10',
            playerValue: 535,
            playerPoints: 85,
          );
        };
      case 'solo-summary':
        return (ref) {
          final match = MatchManager(totalRounds: 3, gameMode: GameMode.practice);
          match.generateMatch();
          ref.read(matchProvider).value = match;
          return const SoloSummaryScreen();
        };
      case 'stats':
        return (ref) => const StatsScreen();
      case 'account':
        return (ref) => const AccountScreen();
      case 'achievements':
        return (ref) => const AchievementsScreen();
      case 'game':
        return (ref) {
          ref.read(matchProvider).value = null;
          final round = ref.read(roundProvider);
          round.startRoundWithData(numbers: [75, 7, 10, 2, 5, 1], targets: [542]);
          return const GameScreen();
        };
      default:
        return (ref) => const MainScreen();
    }
  }

  Future<void> _runCaptureLoop() async {
    for (final t in _targets) {
      final outDir = Directory('$_outRoot/${t.dir}');
      if (!outDir.existsSync()) outDir.createSync(recursive: true);

      for (final scene in t.scenes) {
        final sceneIndex = _allScenes.indexOf(scene);
        final num = (sceneIndex + 1).toString().padLeft(2, '0');
        final fileBase = '$num-$scene';
        final rel = '${t.dir}/$fileBase.png';
        // Set the CURRENT shot id BEFORE setState so any overflow error thrown
        // during the build / _settle() layout+paint pass attributes to this shot.
        _currentShotId = '${t.dir}/$fileBase';
        try {
          // Mount the scene and CHECK we actually landed on it. One retry with a
          // forced fresh mount clears the transient case; a second failure is
          // recorded and fails the validator rather than silently shipping a
          // screenshot of the wrong screen.
          // Build ONCE — the builders mutate shared provider state, so the retry
          // below must remount this same widget rather than rebuild it.
          final screen = _builderFor(scene)(ref);
          var landed =
              await _mountAndVerify(screen, scene, t, '${t.dir}/$fileBase');
          if (!landed) {
            _sceneRetries.add('$_currentShotId: '
                '${_expectedWidget[scene]} not mounted — retrying');
            // Blank the tree first so the retry is a genuine remount and not a
            // no-op rebuild of an identical widget.
            setState(() {
              _currentScreen = null;
              _shotId = '${t.dir}/$fileBase#blank';
            });
            await _awaitFrame();
            landed = await _mountAndVerify(
                screen, scene, t, '${t.dir}/$fileBase#retry');
            if (!landed) {
              _sceneMismatches.add('$_currentShotId: '
                  '${_expectedWidget[scene]} still not mounted after retry');
            }
          }

          final renderObject = _boundaryKey.currentContext?.findRenderObject();
          if (renderObject is! RenderRepaintBoundary) {
            _skipped.add('$_shotId: no RenderRepaintBoundary');
            continue;
          }

          final image = await renderObject.toImage(pixelRatio: t.ratio);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          if (byteData == null) {
            _skipped.add('$_shotId: PNG encoding failed');
            continue;
          }

          final file = File('${outDir.path}/$fileBase.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
          _writtenFiles.add(file.path);
          // Record the authoritative manifest entry for this written shot.
          // `overflow` reflects whatever the FlutterError hook attributed to
          // this shot id during its layout/paint (empty => no overflow).
          final overflow = _overflowByShot[_currentShotId] ?? const <String>[];
          // `layout_errors` are assertion failures that leave a subtree
          // UNPAINTED — a shot can be pixel-perfect in size and still be blank.
          final layoutErrors =
              _layoutErrorsByShot[_currentShotId] ?? const <String>[];
          _manifestShots.add(<String, dynamic>{
            'file': rel,
            'store': t.store,
            'device': t.device,
            'dir': t.dir,
            'scene': scene,
            'expected_w': (t.w * t.ratio).round(),
            'expected_h': (t.h * t.ratio).round(),
            'overflow': overflow.isNotEmpty,
            'overflow_details': List<String>.from(overflow),
            'layout_error': layoutErrors.isNotEmpty,
            'layout_error_details': List<String>.from(layoutErrors),
          });
          // ignore: avoid_print
          print('CAPTURED ${file.path}');
        } catch (e, st) {
          _skipped.add('$_shotId: $e');
          stderr.writeln('SCREENSHOT_ERROR $_shotId: $e\n$st');
        }
      }
    }

    _writeManifest();

    // ignore: avoid_print
    print('SCREENSHOTS_WRITTEN_TO: $_outRoot');
    for (final path in _writtenFiles) {
      // ignore: avoid_print
      print(path);
    }
    if (_skipped.isNotEmpty) {
      // ignore: avoid_print
      print('SKIPPED: ${_skipped.join(' | ')}');
    }
    if (_settleTimeouts.isNotEmpty) {
      // ignore: avoid_print
      print('SETTLE_TIMEOUT (may be mid-animation, inspect these): '
          '${_settleTimeouts.join(' | ')}');
    }
    if (_sceneRetries.isNotEmpty) {
      // ignore: avoid_print
      print('SCENE_RETRY (landed on the wrong screen, recovered): '
          '${_sceneRetries.join(' | ')}');
    }
    if (_sceneMismatches.isNotEmpty) {
      // ignore: avoid_print
      print('SCENE_MISMATCH (PNG shows the WRONG screen): '
          '${_sceneMismatches.join(' | ')}');
    }
    if (_layoutErrorsByShot.isNotEmpty) {
      // ignore: avoid_print
      print('LAYOUT_ERRORS (subtree unpainted — these shots are BLANK): '
          '${_layoutErrorsByShot.keys.join(' | ')}');
    }

    exit(0);
  }

  /// Writes the AUTHORITATIVE capture manifest that
  /// scripts/validate_screenshots.py reads. `file` paths are relative to
  /// _outRoot; expected_w/h are the exact store pixel sizes (logical x ratio).
  /// skipped[] lists shots that never produced a PNG (each a validator failure).
  void _writeManifest() {
    final manifest = <String, dynamic>{
      'generated': DateTime.now().toUtc().toIso8601String(),
      'out_root': _outRoot,
      'shots': _manifestShots,
      'skipped': _skipped,
      'settle_timeouts': _settleTimeouts,
      'scene_retries': _sceneRetries,
      'scene_mismatches': _sceneMismatches,
    };
    final path = '$_outRoot/capture_manifest.json';
    File(path).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest));
    // ignore: avoid_print
    print('MANIFEST_WRITTEN: $path');
  }

  /// Whether a widget whose runtimeType is named [typeName] is mounted anywhere
  /// under [ctx]. Debug-harness only — matching on a type NAME would break under
  /// release obfuscation, but this entry point never ships.
  bool _isMountedUnder(BuildContext ctx, String typeName) {
    var found = false;
    void walk(Element el) {
      if (found) return;
      if (el.widget.runtimeType.toString() == typeName) {
        found = true;
        return;
      }
      el.visitChildren(walk);
    }

    ctx.visitChildElements(walk);
    return found;
  }

  /// Mounts an ALREADY-BUILT [screen] for [t] under [shotId] and settles.
  /// Returns whether the expected widget for [scene] is actually mounted inside
  /// the capture boundary (see [_expectedWidget]); true when no expectation is
  /// registered.
  ///
  /// Takes a pre-built widget rather than a scene name ON PURPOSE. The scene
  /// builders MUTATE shared provider state — the 'results' builder alone calls
  /// startRoundWithData(), endRound(), addPlayer() and recordSubmission(). An
  /// earlier version of the retry path re-invoked the builder, running those
  /// side effects a second time; that corrupted the seeded state and cascaded
  /// into the FOLLOWING target's shots (one failure at the end of ios/ipad13
  /// was followed by five consecutive play/phone failures). Build once per shot,
  /// mount as many times as needed.
  Future<bool> _mountAndVerify(
      Widget screen, String scene, _Target t, String shotId) async {
    setState(() {
      _target = t;
      _shotId = shotId;
      _currentScreen = screen;
    });
    await _settle();
    final expected = _expectedWidget[scene];
    if (expected == null) return true;
    final ctx = _boundaryKey.currentContext;
    // No live boundary context means there is nothing to photograph; let the
    // existing 'no RenderRepaintBoundary' skip path report that rather than
    // double-failing here.
    if (ctx == null || !ctx.mounted) return true;
    return _isMountedUnder(ctx, expected);
  }

  /// Awaits the next frame, but never blocks longer than [_frameWaitTimeout] —
  /// see that constant for why an un-timed-out `endOfFrame` can hang a run.
  Future<void> _awaitFrame() => WidgetsBinding.instance.endOfFrame
      .timeout(_frameWaitTimeout, onTimeout: () {});

  /// Pumps frames until nothing is animating, so async-decoded content (SVGs,
  /// fonts, images) and post-frame callbacks complete — and no shot is
  /// rasterized mid entrance-animation — before we rasterize.
  ///
  /// A running AnimationController drives a ticker, which registers a transient
  /// frame callback, so `transientCallbackCount == 0` means the tree is visually
  /// at rest. This replaced a fixed ~770ms wait that *raced* GameScreen's 800ms
  /// entrance controller: large targets (mac 2880x1800) took long enough to
  /// rasterize that they landed after the animation, but the small phone targets
  /// rendered fast enough to beat it and captured a faded-out, near-blank frame.
  ///
  /// No screen animates on a `repeat()` loop, so this always reaches rest;
  /// [_settleTimeout] is a safety net if a looping animation is ever added.
  Future<void> _settle() async {
    // Minimum pump: lets first-frame post-frame callbacks register their
    // tickers, so we never sample the count before any animation has started.
    for (var i = 0; i < 6; i++) {
      await _awaitFrame();
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }

    final deadline = DateTime.now().add(_settleTimeout);
    var quietFrames = 0;
    while (quietFrames < _quietFramesRequired) {
      if (!DateTime.now().isBefore(deadline)) {
        _settleTimeouts.add(_currentShotId);
        break;
      }
      // An idle tree schedules no frames on its own, so ask for one; otherwise
      // `endOfFrame` would wait forever once everything has settled.
      WidgetsBinding.instance.scheduleFrame();
      await _awaitFrame();
      // Require consecutive quiet frames so a controller that chains into
      // another is not mistaken for a fully settled tree.
      quietFrames =
          WidgetsBinding.instance.transientCallbackCount == 0 ? quietFrames + 1 : 0;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    // Final breather for async decode work already scheduled above.
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final screen = _currentScreen;

    return MaterialApp(
      // A fresh key per shot forces a full remount (fresh Navigator/route)
      // instead of Flutter diff-updating MaterialApp.home.
      key: ValueKey(_shotId),
      theme: AppTheme.getTheme(_heroTheme),
      debugShowCheckedModeBanner: false,
      home: screen == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              body: Center(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: _target.w,
                  maxWidth: _target.w,
                  minHeight: _target.h,
                  maxHeight: _target.h,
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: Size(_target.w, _target.h),
                      devicePixelRatio: _target.ratio,
                    ),
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: SizedBox(
                        width: _target.w,
                        height: _target.h,
                        child: screen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
