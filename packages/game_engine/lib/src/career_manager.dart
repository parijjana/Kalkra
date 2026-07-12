import 'elo_calculator.dart';

class RivalInfo {
  final String name;
  final int eloShift;
  final DateTime date;
  final bool wasSolo;

  RivalInfo({required this.name, required this.eloShift, required this.date, this.wasSolo = false});

  Map<String, dynamic> toJson() => {
    'name': name,
    'eloShift': eloShift,
    'date': date.toIso8601String(),
    'wasSolo': wasSolo,
  };

  factory RivalInfo.fromJson(Map<String, dynamic> json) => RivalInfo(
    name: json['name'],
    eloShift: json['eloShift'],
    date: DateTime.parse(json['date']),
    wasSolo: json['wasSolo'] ?? false,
  );
}

class CareerManager {
  final String playerName;
  final int elo;
  final int matchesWon;
  final int matchesPlayed;
  final double avgSpeedSeconds;
  final double avgAccuracy;
  final int roundsTracked;
  final int currentStreak;
  final int bestStreak;
  final bool soundEnabled;
  final bool musicEnabled;
  final double sfxVolume;
  final double bgmVolume;
  final Set<String> enabledTracks; // New: Set of track filenames
  final List<RivalInfo> rivals;
  final Set<String> unlockedAchievements;

  CareerManager({
    this.playerName = 'Guest',
    this.elo = 1200,
    this.matchesWon = 0,
    this.matchesPlayed = 0,
    this.avgSpeedSeconds = 0.0,
    this.avgAccuracy = 0.0,
    this.roundsTracked = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.sfxVolume = 0.8,
    this.bgmVolume = 0.4,
    this.enabledTracks = const {'vaporware.ogg', 'good_endings.ogg', 'starfield.ogg'},
    this.rivals = const [],
    this.unlockedAchievements = const {},
  });

  CareerManager copyWith({
    String? playerName,
    int? elo,
    int? matchesWon,
    int? matchesPlayed,
    double? avgSpeedSeconds,
    double? avgAccuracy,
    int? roundsTracked,
    int? currentStreak,
    int? bestStreak,
    bool? soundEnabled,
    bool? musicEnabled,
    double? sfxVolume,
    double? bgmVolume,
    Set<String>? enabledTracks,
    List<RivalInfo>? rivals,
    Set<String>? unlockedAchievements,
  }) {
    return CareerManager(
      playerName: playerName ?? this.playerName,
      elo: elo ?? this.elo,
      matchesWon: matchesWon ?? this.matchesWon,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      avgSpeedSeconds: avgSpeedSeconds ?? this.avgSpeedSeconds,
      avgAccuracy: avgAccuracy ?? this.avgAccuracy,
      roundsTracked: roundsTracked ?? this.roundsTracked,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      enabledTracks: enabledTracks ?? this.enabledTracks,
      rivals: rivals ?? this.rivals,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'elo': elo,
    'matchesWon': matchesWon,
    'matchesPlayed': matchesPlayed,
    'avgSpeedSeconds': avgSpeedSeconds,
    'avgAccuracy': avgAccuracy,
    'roundsTracked': roundsTracked,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'soundEnabled': soundEnabled,
    'musicEnabled': musicEnabled,
    'sfxVolume': sfxVolume,
    'bgmVolume': bgmVolume,
    'enabledTracks': enabledTracks.toList(),
    'rivals': rivals.map((r) => r.toJson()).toList(),
    'unlockedAchievements': unlockedAchievements.toList(),
  };

  factory CareerManager.fromJson(Map<String, dynamic> json) {
    List<String> tracks = (json['enabledTracks'] as List?)?.map((e) => e.toString()).toList() ??
                          ['vaporware.ogg', 'good_endings.ogg', 'starfield.ogg'];

    // Migration: ensure .ogg extensions (including .mid → .ogg for good_endings)
    tracks = tracks.map((t) {
      if (t.endsWith('.mp3') || t.endsWith('.wav') || t.endsWith('.mid')) {
        return '${t.split('.').first}.ogg';
      }
      return t;
    }).toList();

    return CareerManager(
      playerName: json['playerName'] ?? 'Guest',
      elo: json['elo'] ?? 1200,
      matchesWon: json['matchesWon'] ?? 0,
      matchesPlayed: json['matchesPlayed'] ?? 0,
      avgSpeedSeconds: (json['avgSpeedSeconds'] ?? 0.0).toDouble(),
      avgAccuracy: (json['avgAccuracy'] ?? 0.0).toDouble(),
      roundsTracked: json['roundsTracked'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      soundEnabled: json['soundEnabled'] ?? true,
      musicEnabled: json['musicEnabled'] ?? true,
      sfxVolume: (json['sfxVolume'] ?? 0.8).toDouble(),
      bgmVolume: (json['bgmVolume'] ?? 0.4).toDouble(),
      enabledTracks: tracks.toSet(),
      rivals: (json['rivals'] as List?)?.map((r) => RivalInfo.fromJson(r)).toList() ?? const [],
      unlockedAchievements: (json['unlockedAchievements'] as List?)?.map((e) => e.toString()).toSet() ?? const {},
    );
  }
}
