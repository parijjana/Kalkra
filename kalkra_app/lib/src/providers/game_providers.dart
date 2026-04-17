import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:game_engine/game_engine.dart';
import '../services/career_persistence.dart';

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
}

/// Provider for the current game settings.
final settingsProvider = Provider<ValueNotifier<GameSettings>>((ref) {
  return ValueNotifier(GameSettings());
});

/// Provider for the active match.
final matchProvider = Provider<ValueNotifier<MatchManager?>>((ref) {
  return ValueNotifier(null);
});

/// Provider for the session manager.
final sessionProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

/// Provider for SharedPreferences instance.
/// This should be overridden in the main ProviderScope.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

/// Provider for the CareerPersistence service.
final careerPersistenceProvider = Provider<CareerPersistence>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CareerPersistence(prefs);
});

/// Provider for the CareerManager (persistent state).
/// We use a Notifier to handle automatic saving when state changes.
final careerProvider = NotifierProvider<CareerNotifier, CareerManager>(CareerNotifier.new);

class CareerNotifier extends Notifier<CareerManager> {
  @override
  CareerManager build() {
    final persistence = ref.watch(careerPersistenceProvider);
    return persistence.load();
  }

  void setPlayerName(String name) {
    state.setPlayerName(name);
    _save();
    ref.notifyListeners();
  }

  void updatePerformance({required double secondsToSubmit, required int proximityToTarget}) {
    state.recordRoundPerformance(secondsToSubmit: secondsToSubmit, proximityToTarget: proximityToTarget);
    _save();
    ref.notifyListeners();
  }

  void updateMatchResult({required bool didWin, required int opponentElo, required String opponentName}) {
    state.recordMatchResult(didWin: didWin, opponentElo: opponentElo, opponentName: opponentName);
    _save();
    ref.notifyListeners();
  }

  void applyEloShift(int shift, String opponentName) {
    state.applyEloShift(shift, opponentName);
    _save();
    ref.notifyListeners();
  }

  void clear() {
    state = CareerManager();
    ref.read(careerPersistenceProvider).clear();
  }

  Future<void> _save() async {
    await ref.read(careerPersistenceProvider).save(state);
  }
}

/// Provider for the round manager (logic for a single round).
final roundProvider = Provider<RoundManager>((ref) {
  return RoundManager();
});

/// Stream provider for transport events.
final gameEventStreamProvider = StreamProvider<GameEvent>((ref) {
  final transport = ref.watch(transportProvider);
  return transport.eventStream;
});
