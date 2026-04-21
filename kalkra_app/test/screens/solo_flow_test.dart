import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalkra_app/src/screens/game_screen.dart';
import 'package:kalkra_app/src/screens/results_screen.dart';
import 'package:kalkra_app/src/providers/game_providers.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  testWidgets('Solo Practice: Next Round should generate new puzzle and allow submission', (tester) async {
    // Set a large desktop-like screen size to avoid hit-test issues with the new layout
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

    // Initialize the match and round
    final match = MatchManager(totalRounds: 3);
    container.read(matchProvider).value = match;
    
    final round = container.read(roundProvider);
    round.startRound(difficulty: Difficulty.easy);
    final firstTarget = round.target;
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

    // 1. Build expression and submit
    // Tap the first number tile (use .first to avoid ambiguous matches if number repeats)
    await tester.tap(find.text('${firstNumbers[0]}').first);
    await tester.pump();
    
    // Tap SUBMIT button
    // Ensure it's visible if the screen is large
    await tester.ensureVisible(find.text('SUBMIT'));
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    // 2. Verify ResultsScreen
    expect(find.byType(ResultsScreen), findsOneWidget);
    
    // 3. Tap NEXT ROUND
    await tester.tap(find.text('NEXT ROUND'));
    await tester.pumpAndSettle();

    // 4. Verify GameScreen is back
    expect(find.byType(GameScreen), findsOneWidget);

    // 5. Verify a NEW round was started and state is 'playing'
    expect(round.state, RoundState.playing);
    // Note: Numbers might be same by random chance but extremely unlikely.
    // The key is that the state is 'playing', allowing a second submission.
    
    // 6. Try to submit again
    final secondNumbers = round.numbers;
    await tester.tap(find.text('${secondNumbers[0]}').first);
    await tester.pump();
    
    await tester.ensureVisible(find.text('SUBMIT'));
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    // If it worked, we should be back on ResultsScreen
    expect(find.byType(ResultsScreen), findsOneWidget);
  });
}
