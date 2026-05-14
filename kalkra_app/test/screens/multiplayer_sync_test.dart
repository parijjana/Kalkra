import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalkra_app/src/screens/staging_screen.dart';
import 'package:kalkra_app/src/screens/game_screen.dart';
import 'package:kalkra_app/src/screens/results_screen.dart';
import 'package:kalkra_app/src/widgets/countdown_overlay.dart';
import 'package:kalkra_app/src/providers/providers.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:kalkra_app/src/config/navigator_key.dart';

class FakeHostTransport extends LanHostTransport {
  final _controller = StreamController<GameEvent>.broadcast();

  @override
  Stream<GameEvent> get eventStream => _controller.stream;

  @override
  String get myId => 'host';

  @override
  Future<void> sendEvent(GameEvent event) async {
    _controller.add(event);
  }

  @override
  Future<void> disconnect() async {
    await _controller.close();
  }
}

class MockTransportNotifier extends TransportNotifier {
  final IGameTransport _mock;
  MockTransportNotifier(this._mock);
  @override
  IGameTransport build() => _mock;
}

class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

void main() {
  group('Multiplayer: Lobby & Sync Integration', () {
    testWidgets('Team renaming on host should trigger UI rebuild', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceIdProvider.overrideWith((ref) => Future.value('test-host')),
        ],
      );

      final session = container.read(sessionProvider);
      session.addPlayer('host', 'HostPlayer', isHost: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const StagingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial name check
      expect(find.text('TEAM 1'), findsOneWidget);

      // Perform Rename
      session.renameTeam(1, 'Calculators');
      container.read(sessionUpdateProvider.notifier).trigger();
      await tester.pumpAndSettle();

      expect(find.text('CALCULATORS'), findsOneWidget);
    });

    testWidgets('Auto-navigation to GameScreen when match status changes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceIdProvider.overrideWith((ref) => Future.value('test-client')),
        ],
      );

      // Setup session
      final session = container.read(sessionProvider);
      session.addPlayer('me', 'ClientPlayer');
      session.assignTeam('me', 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const StagingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StagingScreen), findsOneWidget);

      // Simulate network event: hostStartedMatch
      final round = container.read(roundProvider);
      round.startRoundWithData(numbers: [1, 2, 3, 4, 5, 6], targets: [100]);

      container
          .read(matchStatusProvider.notifier)
          .setStatus(MatchStatus.playing);
      await tester.pumpAndSettle();

      // Verify automatic transition
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('Early termination triggers when all players submit', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final hostTransport = FakeHostTransport();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transportProvider.overrideWith(
            () => MockTransportNotifier(hostTransport),
          ),
          deviceIdProvider.overrideWith((ref) => Future.value('test-host')),
        ],
      );

      // Initialize sync
      container.read(sessionSyncProvider);

      // Setup Host Session
      final session = container.read(sessionProvider);
      session.addPlayer('host', 'Host', isHost: true);
      session.addPlayer('client1', 'Client');
      session.assignTeam('host', 1);
      session.assignTeam('client1', 2);

      final match = MatchManager(
        totalRounds: 5,
        gameMode: GameMode.multiplayer,
      );
      match.generateMatch();
      container.read(matchProvider).value = match;

      final round = container.read(roundProvider);
      round.startRound(
        data: MatchRoundData.mock(numbers: [1, 2, 3], targets: [6]),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure GameScreen is visible
      expect(find.byType(GameScreen), findsOneWidget);

      // Host submits
      session.recordSubmission('host', '1+1', 0);

      // At this point, we are still on GameScreen (waiting for client1)
      expect(find.byType(ResultsScreen), findsNothing);

      // Simulate client1 submission event via the transport
      hostTransport.sendEvent(
        GameEvent(
          type: GameEventType.submissionReceived,
          payload: {'playerId': 'client1', 'expression': '2+2'},
        ),
      );

      // Wait for stream event to propagate and navigation to settle
      await tester.pump(); // Handle stream
      await tester.pump(const Duration(milliseconds: 100)); // Allow async logic
      await tester.pumpAndSettle(); // Handle transition

      // Now it should have transitioned to ResultsScreen automatically
      expect(find.byType(ResultsScreen), findsOneWidget);
    });

    testWidgets('Client correctly initializes MatchManager from network data', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceIdProvider.overrideWith((ref) => Future.value('test-client')),
        ],
      );

      // Initialize sync
      container.read(sessionSyncProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state (solo)
      expect(find.textContaining('SOLO'), findsOneWidget);

      // Simulate 'roundStarted' with match metadata
      container
          .read(transportProvider)
          .sendEvent(
            GameEvent(
              type: GameEventType.roundStarted,
              payload: {
                'numbers': [1, 2, 3, 4, 5, 6],
                'targets': [100],
                'totalRounds': 10,
                'currentRound': 3,
                'gameMode': GameMode.multiplayer.index,
              },
            ),
          );

      await tester.pump(); // Handle stream
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(); // Handle UI update

      // Verify label changed to ROUND 3/10
      expect(find.textContaining('ROUND 3/10'), findsOneWidget);
      expect(find.textContaining('SOLO'), findsNothing);

      await tester.pumpWidget(Container());
    });

    testWidgets('GameScreen stays in countdown when startTime is in future', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceIdProvider.overrideWith((ref) => Future.value('test-client')),
        ],
      );

      // Initialize sync
      container.read(sessionSyncProvider);

      final futureStartTime = DateTime.now().millisecondsSinceEpoch + 10000;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Trigger start with future time
      container
          .read(transportProvider)
          .sendEvent(
            GameEvent(
              type: GameEventType.roundStarted,
              payload: {
                'numbers': [1, 2, 3, 4, 5, 6],
                'targets': [100],
                'startTime': futureStartTime,
              },
            ),
          );

      await tester.pump(); // Handle stream
      await tester.pump(const Duration(milliseconds: 100)); // Allow UI to react

      // Verify Countdown is visible
      expect(find.byType(CountdownOverlay), findsOneWidget);
    });

    testWidgets('Client auto-disconnects if host heartbeat is lost', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final clientTransport = LanClientTransport();
      final testNavKey = GlobalKey<NavigatorState>();
      final mockObserver = MockNavigatorObserver();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transportProvider.overrideWith(
            () => MockTransportNotifier(clientTransport),
          ),
          deviceIdProvider.overrideWith((ref) => Future.value('test-client')),
          navigatorKeyProvider.overrideWithValue(testNavKey),
        ],
      );

      // Initialize sync
      container.read(sessionSyncProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: testNavKey,
            navigatorObservers: [mockObserver],
            home: const StagingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we are in lobby
      expect(find.byType(StagingScreen), findsOneWidget);

      // Trigger error manually
      container
          .read(transportProvider)
          .sendEvent(
            GameEvent(
              type: GameEventType.error,
              payload: {'message': 'Mock error'},
            ),
          );

      // Extensive pumping to ensure navigation logic completes
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify navigation was triggered
      expect(
        mockObserver.pushedRoutes.isNotEmpty,
        isTrue,
        reason: 'Navigation should have been triggered',
      );
    });
  });
}
