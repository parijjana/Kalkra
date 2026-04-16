import 'number_generator.dart';

class GameSettings {
  final String playerName;
  final Difficulty difficulty;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool darkMode;

  GameSettings({
    this.playerName = 'Player',
    this.difficulty = Difficulty.medium,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.darkMode = false,
  });

  GameSettings copyWith({
    String? playerName,
    Difficulty? difficulty,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? darkMode,
  }) {
    return GameSettings(
      playerName: playerName ?? this.playerName,
      difficulty: difficulty ?? this.difficulty,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'difficulty': difficulty.index,
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'darkMode': darkMode,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      playerName: json['playerName'] as String? ?? 'Player',
      difficulty: Difficulty.values[json['difficulty'] as int],
      soundEnabled: json['soundEnabled'] as bool,
      musicEnabled: json['musicEnabled'] as bool,
      darkMode: json['darkMode'] as bool,
    );
  }
}
