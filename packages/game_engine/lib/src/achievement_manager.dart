import 'models/achievement.dart';
import 'achievement_registry.dart';

class AchievementManager {
  final Set<String> unlockedIds;
  final void Function(Achievement achievement) onUnlock;

  AchievementManager({
    required this.unlockedIds,
    required this.onUnlock,
  });

  void handleEvent(AchievementEvent event) {
    for (final achievement in AchievementRegistry.all) {
      if (unlockedIds.contains(achievement.id)) continue;

      if (_shouldUnlock(achievement, event)) {
        onUnlock(achievement);
      }
    }
  }

  bool _isPrime(num n) {
    if (n < 2) return false;
    if (n % 1 != 0) return false;
    final int val = n.toInt();
    for (int i = 2; i <= val / 2; i++) {
      if (val % i == 0) return false;
    }
    return true;
  }

  bool _shouldUnlock(Achievement achievement, AchievementEvent event) {
    final data = event.data;

    switch (achievement.id) {
      // Speed & Time
      case 'speed_1':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['isExact'] ?? false) &&
            (data['seconds'] ?? 100.0) < 3.0;
      case 'speed_2':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['isExact'] ?? false) &&
            (data['secondsLeft'] ?? 0) <= 1;
      case 'speed_4':
        return event.type == AchievementEventType.actionPerformed &&
            data['action'] == 'speed_demon_streak' &&
            (data['count'] ?? 0) >= 3;

      // Precision & Constraint
      case 'precision_1':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['isExact'] ?? false) &&
            (data['numberCount'] ?? 100) == 2;
      case 'precision_2':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['isExact'] ?? false) &&
            (data['numberCount'] ?? 0) == 6;
      case 'precision_3':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['isExact'] ?? false) &&
            !(data['ops'] as List<String>? ?? []).contains('+');
      case 'precision_5':
        if (event.type != AchievementEventType.expressionSubmitted || !(data['isExact'] ?? false)) return false;
        final intermediates = data['intermediates'] as List<num>? ?? [];
        if (intermediates.isEmpty) return false;
        return intermediates.every((n) => _isPrime(n));

      // Endurance & Grind
      case 'endurance_1':
        return event.type == AchievementEventType.roundCompleted &&
            (data['roundIndex'] ?? 0) >= 20 &&
            data['gameMode'] == 'endless';
      case 'endurance_2':
        return event.type == AchievementEventType.matchCompleted &&
            (data['totalMatches'] ?? 0) >= 100;
      case 'endurance_3':
        return event.type == AchievementEventType.roundCompleted &&
            (data['livesLeft'] ?? 0) == 1 &&
            (data['lowLifeRounds'] ?? 0) >= 5;

      // Quirky & Easter Eggs
      case 'quirky_1':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['value'] ?? 1) == 0;
      case 'quirky_2':
        return event.type == AchievementEventType.expressionSubmitted &&
            data['error'] != null &&
            data['error'].toString().contains('zero');
      case 'quirky_3':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['value'] ?? 0) == 42;
      case 'quirky_5':
        return event.type == AchievementEventType.expressionSubmitted &&
            (data['isTokenOnly'] ?? false);

      // Multiplayer
      case 'multiplayer_1':
        return event.type == AchievementEventType.matchCompleted &&
            (data['playerCount'] ?? 0) >= 4;
      case 'multiplayer_2':
        return event.type == AchievementEventType.eloChanged &&
            (data['opponentEloDiff'] ?? 0) >= 200 &&
            (data['isWin'] ?? false);

      default:
        return false;
    }
  }
}
