import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:game_engine/game_engine.dart';
import 'package:uuid/uuid.dart';
import '../config/device_util.dart';
import '../config/navigator_key.dart';
import '../screens/main_screen.dart';

// Import newly created files to resolve undefined references
import 'career_providers.dart';

export 'career_providers.dart';

/// Provider for the transport layer.
/// Defaults to NullTransport for solo play.
final transportProvider = NotifierProvider<TransportNotifier, IGameTransport>(TransportNotifier.new);

class TransportNotifier extends Notifier<IGameTransport> {
  @override
  IGameTransport build() {
    return NullTransport();
  }

  void setTransport(IGameTransport newTransport) {
    state = newTransport;
  }

  void disconnect() {
    state.disconnect();
  }
}

/// Provider for game events coming from the transport layer.
final gameEventStreamProvider = StreamProvider<GameEvent>((ref) {
  return ref.watch(transportProvider).eventStream;
});

/// Provider for the unique device ID.
final deviceIdProvider = FutureProvider<String>((ref) async {
  return await DeviceIdUtil.getDeviceId();
});

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

/// Provider for the active match.
final matchProvider = Provider<ValueNotifier<MatchManager?>>((ref) {
  return ValueNotifier(null);
});

/// Provider for the session manager (internal data).
final sessionProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

/// A dummy notifier to trigger rebuilds when the session manager changes.
final sessionUpdateProvider = NotifierProvider<SessionUpdateNotifier, int>(SessionUpdateNotifier.new);

class SessionUpdateNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void trigger() => state++;
}

/// A service provider that synchronizes the SessionManager and Game State with network events.
final sessionSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (prev, next) {
    next.whenData((event) {
      final session = ref.read(sessionProvider);
      final transport = ref.read(transportProvider);
      final round = ref.read(roundProvider);
      final isHost = transport is LanHostTransport;

      switch (event.type) {
        case GameEventType.playerJoined:
          final player = PlayerInfo.fromJson(event.payload);
          session.addPlayer(
            player.id,
            player.name,
            elo: player.currentElo,
            isHost: player.isHost,
            deviceId: player.deviceId,
          );

          if (isHost) {
            final totalCount = session.players.length;
            if (totalCount <= 6) {
              int team1 = session.players.values.where((p) => p.teamId == 1).length;
              int team2 = session.players.values.where((p) => p.teamId == 2).length;
              session.assignTeam(player.id, team1 <= team2 ? 1 : 2);
            } else if (totalCount == 7) {
              final ids = session.players.keys.toList();
              for (int i = 0; i < ids.length; i++) {
                session.assignTeam(ids[i], (i % 4) + 1);
              }
            } else {
              int bestTeam = 1;
              int minSize = 100;
              for (int t = 1; t <= 4; t++) {
                int size = session.players.values.where((p) => p.teamId == t).length;
                if (size < minSize) {
                  minSize = size;
                  bestTeam = t;
                }
              }
              session.assignTeam(player.id, bestTeam);
            }
            _broadcastLobbyState(transport, session);
          }
          break;
        case GameEventType.playerLeft:
          final id = event.payload['playerId'];
          session.removePlayer(id);
          if (isHost) _broadcastLobbyState(transport, session);
          break;
        case GameEventType.playerReady:
          final id = event.payload['playerId'] ?? (isHost ? 'host' : 'me');
          final ready = event.payload['ready'] as bool;
          session.setPlayerReady(id, ready);
          if (isHost) _broadcastLobbyState(transport, session);
          break;
        case GameEventType.teamAssignment:
          if (isHost) {
            final id = event.payload['playerId'];
            final teamId = event.payload['teamId'] as int;
            session.assignTeam(id, teamId);
            _broadcastLobbyState(transport, session);
          }
          break;
        case GameEventType.teamRename:
          final teamId = event.payload['teamId'] as int;
          final name = event.payload['name'] as String;
          session.renameTeam(teamId, name);
          if (isHost) _broadcastLobbyState(transport, session);
          break;
        case GameEventType.lobbyUpdate:
          if (!isHost) {
            final playersData = event.payload['players'] as List;
            final teamNames = Map<String, dynamic>.from(event.payload['teamNames'] ?? {});
            session.syncLobbyState(players: playersData, names: teamNames);
          }
          break;
        case GameEventType.submissionReceived:
          if (isHost) {
            final playerId = event.payload['playerId'] as String;
            final expression = event.payload['expression'] as String;
            session.recordSubmission(playerId, expression, 0);

            if (session.allAssignedSubmitted) {
              transport.sendEvent(GameEvent(type: GameEventType.roundEnded, payload: {}));
            }
          }
          break;
        case GameEventType.hostStartedMatch:
        case GameEventType.roundStarted:
          if (!isHost) {
            final totalRounds = event.payload['totalRounds'] ?? 5;
            final gameModeIndex = event.payload['gameMode'];
            final gameMode = gameModeIndex != null ? GameMode.values[gameModeIndex] : GameMode.multiplayer;
            final currentRoundIndex = event.payload['currentRound'] ?? 1;

            var match = ref.read(matchProvider).value;
            if (match == null || match.gameMode != gameMode) {
              match = MatchManager(totalRounds: totalRounds, gameMode: gameMode);
              ref.read(matchProvider).value = match;
            }
            match.syncRound(currentRoundIndex);
          }

          final List<int> numbers = List<int>.from(event.payload['numbers']);
          final List<int> targets = event.payload['targets'] != null ? List<int>.from(event.payload['targets']) : [event.payload['target'] as int];
          final jeopardyIndex = event.payload['jeopardy'];
          final lockedOp = event.payload['lockedOperator'];
          final jeopardy = jeopardyIndex != null ? JeopardyType.values[jeopardyIndex] : null;
          final startTime = event.payload['startTime'] as int?;
          final configTitle = event.payload['config'] ?? 'Classic Round';

          ref.read(roundStartTimeProvider.notifier).setTime(startTime);

          final reconstructedData = MatchRoundData.mock(
            numbers: numbers,
            targets: targets,
            jeopardy: jeopardy,
            lockedOperator: lockedOp,
            config: RoundConfig(title: configTitle),
          );

          round.startRound(data: reconstructedData);
          session.resetRoundData();

          ref.read(roundUpdateProvider.notifier).trigger();
          ref.read(matchStatusProvider.notifier).setStatus(MatchStatus.playing);
          break;
        case GameEventType.roundResults:
          final results = Map<String, dynamic>.from(event.payload['playerResults']);
          results.forEach((id, data) {
            final pts = data['points'] as int? ?? 0;
            final expr = data['expression'] as String? ?? '';
            session.recordSubmission(id, expr, pts);
          });

          final bestSolutionJson = event.payload['bestSolution'];
          if (bestSolutionJson != null) {
            round.setBestSolution(SolveResult.fromJson(Map<String, dynamic>.from(bestSolutionJson)));
          }

          final eloShifts = event.payload['eloShifts'];
          if (eloShifts != null) {
            final myId = transport.myId;
            final shiftsMap = Map<String, int>.from(eloShifts);
            if (shiftsMap.containsKey(myId)) {
              ref.read(careerProvider.notifier).applyEloShift(shiftsMap[myId]!, 'Arena Rival', wasSolo: false);
            }
          }

          ref.read(lastResultsProvider.notifier).setResults(event.payload);
          ref.read(matchStatusProvider.notifier).setStatus(MatchStatus.results);
          break;
        case GameEventType.matchEnded:
          final history = event.payload['matchHistory'] as List? ?? [];
          final totalScores = Map<String, dynamic>.from(event.payload['sessionTeamScores'] ?? {});
          session.syncSessionHistory(history: history, totalScores: totalScores);

          ref.read(matchStatusProvider.notifier).setStatus(MatchStatus.lobby);
          ref.read(lastResultsProvider.notifier).setResults(null);
          break;
        case GameEventType.heartbeat:
          break;
        case GameEventType.error:
          ref.read(matchStatusProvider.notifier).setStatus(MatchStatus.lobby);
          ref.read(matchProvider).value = null;
          ref.read(transportProvider).disconnect();
          ref.read(transportProvider.notifier).setTransport(NullTransport());

          final navKey = ref.read(navigatorKeyProvider);
          navKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
          break;
        default:
          break;
      }
      ref.read(sessionUpdateProvider.notifier).trigger();
    });
  });
});

void _broadcastLobbyState(IGameTransport transport, SessionManager session) {
  transport.sendEvent(
    GameEvent(
      type: GameEventType.lobbyUpdate,
      payload: {
        'players': session.getLobbyState(),
        'teamNames': session.getTeamNames(),
      },
    ),
  );
}

/// Provider for the global navigator key.
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return navigatorKey;
});

/// Provider for the current game settings.
final settingsProvider = Provider<ValueNotifier<GameSettings>>((ref) {
  return ValueNotifier(GameSettings());
});

/// Provider for the round manager (logic for a single round).
final roundProvider = Provider<RoundManager>((ref) {
  return RoundManager();
});

enum MatchStatus { lobby, playing, results, finished }

/// Provider for tracking the current match status for auto-navigation.
final matchStatusProvider = NotifierProvider<MatchStatusNotifier, MatchStatus>(MatchStatusNotifier.new);

class MatchStatusNotifier extends Notifier<MatchStatus> {
  @override
  MatchStatus build() => MatchStatus.lobby;
  void setStatus(MatchStatus status) => state = status;
}

/// Provider for the latest round results to facilitate auto-navigation.
final lastResultsProvider = NotifierProvider<LastResultsNotifier, Map<String, dynamic>?>(LastResultsNotifier.new);

class LastResultsNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void setResults(Map<String, dynamic>? results) => state = results;
}

/// Provider for tracking the scheduled synchronized start time of the current round.
final roundStartTimeProvider = NotifierProvider<RoundStartTimeNotifier, int?>(RoundStartTimeNotifier.new);

class RoundStartTimeNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void setTime(int? millis) => state = millis;
}

/// A dummy notifier to trigger rebuilds when the round manager changes.
final roundUpdateProvider = NotifierProvider<RoundUpdateNotifier, int>(RoundUpdateNotifier.new);

class RoundUpdateNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void trigger() => state++;
}

/// Provider for tracking if the host is only spectating.
final isHostOnlyProvider = NotifierProvider<HostOnlyNotifier, bool>(HostOnlyNotifier.new);

class HostOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setState(bool value) => state = value;
}

/// Provider for tracking the current screen ID.
final currentScreenIdProvider = NotifierProvider<ScreenIdNotifier, String>(ScreenIdNotifier.new);

class ScreenIdNotifier extends Notifier<String> {
  @override
  String build() => 'MainScreen';
  void setScreenId(String id) => state = id;
}

/// Provider for tracking if a solo match is currently paused.
final isPausedProvider = NotifierProvider<PauseNotifier, bool>(PauseNotifier.new);

class PauseNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setPaused(bool value) => state = value;
}

/// Provider for tracking host-initiated jeopardy overrides.
final jeopardyOverrideProvider = NotifierProvider<JeopardyOverrideNotifier, bool>(JeopardyOverrideNotifier.new);

class JeopardyOverrideNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setOverride(bool value) => state = value;
}

/// Provider for the achievement manager.
final achievementProvider = Provider<AchievementManager>((ref) {
  final career = ref.watch(careerProvider).value;
  return AchievementManager(
    unlockedIds: career?.unlockedAchievements ?? {},
    onUnlock: (achievement) {
      ref.read(careerProvider.notifier).unlockAchievement(achievement.id);
      ref.read(notificationProvider.notifier).notify(achievement);
    },
  );
});

/// Provider for tracking the latest unlocked achievement.
final notificationProvider = NotifierProvider<NotificationNotifier, Achievement?>(NotificationNotifier.new);

class NotificationNotifier extends Notifier<Achievement?> {
  @override
  Achievement? build() => null;
  void notify(Achievement achievement) {
    state = achievement;
    Future.delayed(const Duration(seconds: 4), () {
      if (state?.id == achievement.id) state = null;
    });
  }
}
