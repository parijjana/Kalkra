import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalkra_app/src/screens/game_screen.dart';
import 'package:kalkra_app/src/screens/results_screen.dart';
import 'package:kalkra_app/src/screens/solo_summary_screen.dart';
import 'package:kalkra_app/src/screens/main_screen.dart';
import 'package:kalkra_app/src/providers/game_providers.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  testWidgets('Solo Flow: Match completion should navigate to SoloSummaryScreen', (tester) async {
    tester.view.physicalSize = const Size(2560, 1440);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Initialize a 1-round match for quick completion
    final match = MatchManager(totalRounds: 1);
    container.read(matchProvider).value = match;
    
    final round = container.read(roundProvider);
    round.startRound(difficulty: Difficulty.easy);
    final firstNumbers = List<int>.from(round.numbers);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Submit the first round
    await tester.tap(find.text('${firstNumbers[0]}').first);
    await tester.pump();
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    // 2. Verify we are on ResultsScreen and button says FINISH MATCH
    expect(find.byType(ResultsScreen), findsOneWidget);
    expect(find.text('FINISH MATCH'), findsOneWidget);

    // 3. Tap FINISH MATCH
    await tester.tap(find.text('FINISH MATCH'));
    await tester.pumpAndSettle();

    // 4. Verify we are on SoloSummaryScreen, NOT MatchSummaryScreen
    expect(find.byType(SoloSummaryScreen), findsOneWidget);
    expect(find.text('SOLO MATCH COMPLETE'), findsOneWidget);
    expect(find.text('MATCH SUMMARY'), findsOneWidget);

    // 5. Tap CONTINUE and verify navigation to MainScreen
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);

    // Clear notification timer to avoid test failure
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
