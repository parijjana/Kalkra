import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalkra_app/src/screens/results_screen.dart';
import 'package:kalkra_app/src/screens/account_screen.dart';
import 'package:kalkra_app/src/screens/stats_screen.dart';
import 'package:kalkra_app/src/screens/history_screen.dart';
import 'package:kalkra_app/src/providers/game_providers.dart';
import 'package:kalkra_app/src/theme/app_theme.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  const themeTypes = [
    AppThemeType.vectorPop,
    AppThemeType.midnightCyber,
    AppThemeType.retroArcade,
    AppThemeType.noir,
  ];

  for (final themeType in themeTypes) {
    group('Theme: ${themeType.name}', () {
      testWidgets('Capture Results Screen', (tester) async {
        await _pumpScreen(tester, themeType, const ResultsScreen(
          playerExpression: '(75 * 7) + 10',
          playerValue: 535,
          playerPoints: 85,
          multiplayerResults: null,
          eloShifts: {'me': 24},
        ));
        expect(find.byType(ResultsScreen), findsOneWidget);
        expect(find.text('542'), findsOneWidget); 
        expect(find.textContaining('85 PTS'), findsOneWidget);
      });

      testWidgets('Capture Account Screen', (tester) async {
        await _pumpScreen(tester, themeType, const AccountScreen());
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.textContaining('ACCOUNT'), findsAtLeast(1));
      });

      testWidgets('Capture Stats Screen', (tester) async {
        await _pumpScreen(tester, themeType, const StatsScreen());
        expect(find.byType(StatsScreen), findsOneWidget);
        expect(find.textContaining('CAREER'), findsAtLeast(1));
      });

      testWidgets('Capture History Screen', (tester) async {
        await _pumpScreen(tester, themeType, const HistoryScreen());
        expect(find.byType(HistoryScreen), findsOneWidget);
        expect(find.textContaining('HISTORY'), findsAtLeast(1));
      });
    });
  }
}

Future<void> _pumpScreen(WidgetTester tester, AppThemeType themeType, Widget screen) async {
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

  // Mock data for screens
  final round = container.read(roundProvider);
  round.startRoundWithData(
    numbers: [75, 7, 10, 2, 5, 1],
    target: 542,
  );
  round.endRound();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.getTheme(themeType),
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    ),
  );

  await tester.pumpAndSettle();
}
