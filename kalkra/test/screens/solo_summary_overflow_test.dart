import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalkra/src/screens/solo_summary_screen.dart';
import 'package:kalkra/src/providers/providers.dart';
import 'package:kalkra/src/services/sound_service.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  setUp(() {
    SoundService().setMusicEnabled(false);
    SoundService().setSoundEnabled(false);
  });

  testWidgets(
    'RESTART MATCH (play again) is visible at a short desktop web viewport',
    (tester) async {
      // Typical laptop browser: wide enough to be "desktop" (>=1024),
      // but only ~700px tall.
      tester.view.physicalSize = const Size(1280, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      final match = MatchManager(totalRounds: 1);
      match.generateMatch();

      final container = ProviderContainer();
      container.read(matchProvider).value = match;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SoloSummaryScreen()),
        ),
      );
      await tester.pump();

      // Both navigation buttons must be present AND on-screen (hit-testable).
      expect(find.text('RESTART MATCH'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final restartRect = tester.getRect(find.text('RESTART MATCH'));
      final continueRect = tester.getRect(find.text('CONTINUE'));
      expect(
        restartRect.bottom <= screen.height,
        isTrue,
        reason: 'RESTART MATCH is pushed below the viewport '
            '(${restartRect.bottom} > ${screen.height})',
      );
      expect(
        continueRect.bottom <= screen.height,
        isTrue,
        reason: 'CONTINUE is pushed below the viewport '
            '(${continueRect.bottom} > ${screen.height})',
      );
    },
  );
}
