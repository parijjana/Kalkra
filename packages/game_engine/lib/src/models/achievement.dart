enum AchievementCategory {
  speed,
  precision,
  endurance,
  quirky,
  multiplayer
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final bool isHidden;
  final String? iconData; // Placeholder for icon identification

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.isHidden = true,
    this.iconData,
  });
}

class AchievementEvent {
  final AchievementEventType type;
  final Map<String, dynamic> data;

  AchievementEvent({required this.type, required this.data});
}

enum AchievementEventType {
  roundCompleted,
  matchCompleted,
  expressionSubmitted,
  eloChanged,
  actionPerformed
}
