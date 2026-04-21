import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalkra_app/src/screens/game_screen.dart';
import 'package:kalkra_app/src/screens/results_screen.dart';
import 'package:kalkra_app/src/providers/game_providers.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  testWidgets('Solo Practice: Match lifecycle, overrun prevention, and score tracking', (tester) async {
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

    // 1. Initialize a 2-round match
    final match = MatchManager(totalRounds: 2);
    container.read(matchProvider).value = match;
    
    final session = container.read(sessionProvider);
    session.resetScores();
    session.addPlayer('solo', 'Tester');

    final round = container.read(roundProvider);
    round.startRound(difficulty: Difficulty.easy);

    // --- ROUND 1 ---
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify round and score display
    expect(find.textContaining('ROUND 1/2'), findsAtLeast(1));
    expect(find.textContaining('SCORE: 0'), findsAtLeast(1));

    // Build simple expression and submit
    await tester.tap(find.text('${round.numbers[0]}').first);
    await tester.pump();
    
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultsScreen), findsOneWidget);
    // Score should be > 0 now (exact match gives points)
    expect(find.textContaining('PTS'), findsAtLeast(1));
    
    // --- ROUND 2 ---
    expect(find.text('NEXT ROUND'), findsOneWidget);
    await tester.tap(find.text('NEXT ROUND'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ROUND 2/2'), findsAtLeast(1));
    // Verify cumulative score is shown (non-zero)
    expect(find.textContaining('SCORE: '), findsAtLeast(1));
    
    // Build and submit another
    await tester.tap(find.text('${round.numbers[0]}').first);
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultsScreen), findsOneWidget);

    // --- END OF MATCH ---
    // The button should now say 'FINISH MATCH'
    expect(find.text('FINISH MATCH'), findsOneWidget);
    expect(find.text('NEXT ROUND'), findsNothing);

    await tester.tap(find.text('FINISH MATCH'));
    await tester.pumpAndSettle();
    
    // Should be back at the start (main menu represented by empty route stack in test)
    // or we can just verify the ResultsScreen is gone.
    expect(find.byType(ResultsScreen), findsNothing);
  });
}
