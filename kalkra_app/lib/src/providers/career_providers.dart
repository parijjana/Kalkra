import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import '../services/career_persistence.dart';
import 'providers.dart';

/// Provider for the CareerPersistence service.
final careerPersistenceProvider = Provider<CareerPersistence>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CareerPersistence(prefs);
});

/// Provider for the CareerManager (persistent state).
final careerProvider = AsyncNotifierProvider<CareerNotifier, CareerManager>(
  CareerNotifier.new,
);

class CareerNotifier extends AsyncNotifier<CareerManager> {
  @override
  Future<CareerManager> build() async {
    final persistence = ref.watch(careerPersistenceProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    return await persistence.load(deviceId);
  }

  Future<void> setPlayerName(String name) async {
    final manager = state.value ?? CareerManager();
    manager.setPlayerName(name);
    state = AsyncData(manager);
    await _save();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final manager = state.value ?? CareerManager();
    manager.setSoundEnabled(enabled);
    state = AsyncData(manager);
    await _save();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    final manager = state.value ?? CareerManager();
    manager.setMusicEnabled(enabled);
    state = AsyncData(manager);
    await _save();
  }

  Future<void> updateProfile({String? playerName}) async {
    final manager = state.value ?? CareerManager();
    if (playerName != null) manager.setPlayerName(playerName);
    state = AsyncData(manager);
    await _save();
  }

  Future<void> updatePerformance({
    required double secondsToSubmit,
    required double proximityToTarget,
  }) async {
    final manager = state.value ?? CareerManager();
    manager.recordRoundPerformance(
      secondsToSubmit: secondsToSubmit,
      proximityToTarget: proximityToTarget,
    );
    state = AsyncData(manager);
    await _save();
  }

  Future<void> applyEloShift(
    int shift,
    String opponentName, {
    bool wasSolo = false,
  }) async {
    final manager = state.value ?? CareerManager();
    manager.applyEloShift(shift, opponentName, wasSolo: wasSolo);
    state = AsyncData(manager);
    await _save();
  }

  Future<void> unlockAchievement(String id) async {
    final manager = state.value ?? CareerManager();
    if (!manager.unlockedAchievements.contains(id)) {
      manager.unlockAchievement(id);
      state = AsyncData(manager);
      await _save();
    }
  }

  Future<void> recordSoloMatch({
    required int score,
    required String mode,
  }) async {
    final manager = state.value ?? CareerManager();
    manager.recordSoloMatchResult(score: score, mode: mode);
    state = AsyncData(manager);
    await _save();
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    await ref.read(careerPersistenceProvider).clear();
    state = AsyncData(CareerManager());
  }

  Future<void> _save() async {
    final manager = state.value;
    if (manager != null) {
      final deviceId = await ref.read(deviceIdProvider.future);
      await ref.read(careerPersistenceProvider).save(manager, deviceId);
    }
  }
}
