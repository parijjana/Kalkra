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
    final manager = state.value;
    if (manager == null) return;
    state = AsyncData(manager.copyWith(playerName: name));
    await _save();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final manager = state.value;
    if (manager == null) return;
    state = AsyncData(manager.copyWith(soundEnabled: enabled));
    await _save();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    final manager = state.value;
    if (manager == null) return;
    state = AsyncData(manager.copyWith(musicEnabled: enabled));
    await _save();
  }

  Future<void> toggleTrack(String fileName) async {
    final manager = state.value;
    if (manager == null) return;
    
    final newTracks = Set<String>.from(manager.enabledTracks);
    if (newTracks.contains(fileName)) {
      newTracks.remove(fileName);
    } else {
      newTracks.add(fileName);
    }
    
    state = AsyncData(manager.copyWith(enabledTracks: newTracks));
    await _save();
  }

  Future<void> setSfxVolume(double volume) async {
    final manager = state.value;
    if (manager == null) return;
    state = AsyncData(manager.copyWith(sfxVolume: volume));
    await _save();
  }

  Future<void> setBgmVolume(double volume) async {
    final manager = state.value;
    if (manager == null) return;
    state = AsyncData(manager.copyWith(bgmVolume: volume));
    await _save();
  }

  Future<void> updatePerformance({
    required double secondsToSubmit,
    required double proximityToTarget,
  }) async {
    final manager = state.value;
    if (manager == null) return;
    
    state = AsyncData(manager.copyWith(
      roundsTracked: manager.roundsTracked + 1,
      avgSpeedSeconds: ((manager.avgSpeedSeconds * manager.roundsTracked) + secondsToSubmit) / (manager.roundsTracked + 1),
      avgAccuracy: ((manager.avgAccuracy * manager.roundsTracked) + proximityToTarget) / (manager.roundsTracked + 1),
    ));
    await _save();
  }

  Future<void> applyEloShift(
    int shift,
    String opponentName, {
    bool wasSolo = false,
  }) async {
    final manager = state.value;
    if (manager == null) return;
    
    final newRivals = List<RivalInfo>.from(manager.rivals);
    newRivals.insert(0, RivalInfo(
      name: opponentName,
      eloShift: shift,
      date: DateTime.now(),
      wasSolo: wasSolo,
    ));
    if (newRivals.length > 50) newRivals.removeLast();

    state = AsyncData(manager.copyWith(
      elo: manager.elo + shift,
      matchesPlayed: manager.matchesPlayed + 1,
      matchesWon: shift > 0 ? manager.matchesWon + 1 : manager.matchesWon,
      rivals: newRivals,
    ));
    await _save();
  }

  Future<void> unlockAchievement(String id) async {
    final manager = state.value;
    if (manager == null) return;
    if (!manager.unlockedAchievements.contains(id)) {
      final newAchievements = Set<String>.from(manager.unlockedAchievements);
      newAchievements.add(id);
      state = AsyncData(manager.copyWith(unlockedAchievements: newAchievements));
      await _save();
    }
  }

  Future<void> recordSoloMatch({
    required int score,
    required String mode,
  }) async {
    final manager = state.value;
    if (manager == null) return;

    final newRivals = List<RivalInfo>.from(manager.rivals);
    newRivals.insert(0, RivalInfo(
      name: 'Solo $mode',
      eloShift: score > 0 ? 5 : 0,
      date: DateTime.now(),
      wasSolo: true,
    ));
    if (newRivals.length > 50) newRivals.removeLast();

    state = AsyncData(manager.copyWith(
      matchesPlayed: manager.matchesPlayed + 1,
      rivals: newRivals,
    ));
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
