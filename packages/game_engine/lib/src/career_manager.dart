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
  String _playerName;
  int _elo;
  int _matchesWon;
  int _matchesPlayed;
  double _avgSpeedSeconds;
  double _avgAccuracy;
  int _roundsTracked;
  int _currentStreak;
  int _bestStreak;
  bool _soundEnabled;
  bool _musicEnabled;
  final List<RivalInfo> _rivals;
  final Set<String> _unlockedAchievements;

  CareerManager({
    String playerName = 'Guest',
    int elo = 1200,
    int matchesWon = 0,
    int matchesPlayed = 0,
    double avgSpeedSeconds = 0.0,
    double avgAccuracy = 0.0,
    int roundsTracked = 0,
    int currentStreak = 0,
    int bestStreak = 0,
    bool soundEnabled = true,
    bool musicEnabled = true,
    List<RivalInfo>? rivals,
    List<String>? unlockedAchievements,
  }) : _playerName = playerName,
       _elo = elo,
       _matchesWon = matchesWon,
       _matchesPlayed = matchesPlayed,
       _avgSpeedSeconds = avgSpeedSeconds,
       _avgAccuracy = avgAccuracy,
       _roundsTracked = roundsTracked,
       _currentStreak = currentStreak,
       _bestStreak = bestStreak,
       _soundEnabled = soundEnabled,
       _musicEnabled = musicEnabled,
       _rivals = rivals ?? [],
       _unlockedAchievements = (unlockedAchievements ?? []).toSet();

  String get playerName => _playerName;
  int get elo => _elo;
  int get matchesWon => _matchesWon;
  int get matchesPlayed => _matchesPlayed;
  double get avgSpeedSeconds => _avgSpeedSeconds;
  double get avgAccuracy => _avgAccuracy;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  List<RivalInfo> get rivals => List.unmodifiable(_rivals);
  Set<String> get unlockedAchievements => Set.unmodifiable(_unlockedAchievements);

  void setPlayerName(String name) {
    _playerName = name;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
  }

  void unlockAchievement(String id) {
    _unlockedAchievements.add(id);
  }

  void recordRoundPerformance({required double secondsToSubmit, required double proximityToTarget}) {
    _avgSpeedSeconds = ((_avgSpeedSeconds * _roundsTracked) + secondsToSubmit) / (_roundsTracked + 1);
    _avgAccuracy = ((_avgAccuracy * _roundsTracked) + proximityToTarget) / (_roundsTracked + 1);
    _roundsTracked++;

    if (proximityToTarget == 0) {
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }
  }

  /// Records the completion of a solo match.
  void recordSoloMatchResult({required int score, required String mode}) {
    _matchesPlayed++;
    
    _rivals.insert(0, RivalInfo(
      name: 'Solo $mode',
      eloShift: score > 0 ? 5 : 0, // Nominal shift for completing a solo match
      date: DateTime.now(),
      wasSolo: true,
    ));

    if (_rivals.length > 50) {
      _rivals.removeLast();
    }
  }

  void recordMultiplayerPerformance({required double secondsToSubmit, required double proximityToTarget, required String opponentName, int eloShift = 0}) {
    _avgSpeedSeconds = ((_avgSpeedSeconds * _roundsTracked) + secondsToSubmit) / (_roundsTracked + 1);
    _avgAccuracy = ((_avgAccuracy * _roundsTracked) + proximityToTarget) / (_roundsTracked + 1);
    _roundsTracked++;

    if (proximityToTarget == 0) {
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    _rivals.insert(0, RivalInfo(
      name: opponentName,
      eloShift: eloShift,
      date: DateTime.now(),
      wasSolo: false,
    ));

    if (_rivals.length > 50) {
      _rivals.removeLast();
    }
  }

  /// Apply a pre-calculated Elo shift (received from host or calculated locally).
  void applyEloShift(int shift, String opponentName, {bool wasSolo = false}) {
    _elo += shift;
    _matchesPlayed++;
    if (shift > 0) _matchesWon++; 

    _rivals.insert(0, RivalInfo(
      name: opponentName,
      eloShift: shift,
      date: DateTime.now(),
      wasSolo: wasSolo,
    ));

    if (_rivals.length > 50) {
      _rivals.removeLast();
    }
  }

  void recordMatchResult({required bool didWin, required int opponentElo, required String opponentName}) {
    final shift = EloCalculator.calculateShift(
      playerElo: _elo,
      didWin: didWin,
      opponentElo: opponentElo,
    );
    applyEloShift(shift, opponentName);
  }

  Map<String, dynamic> toJson() => {
    'playerName': _playerName,
    'elo': _elo,
    'matchesWon': _matchesWon,
    'matchesPlayed': _matchesPlayed,
    'avgSpeedSeconds': _avgSpeedSeconds,
    'avgAccuracy': _avgAccuracy,
    'roundsTracked': _roundsTracked,
    'currentStreak': _currentStreak,
    'bestStreak': _bestStreak,
    'soundEnabled': _soundEnabled,
    'musicEnabled': _musicEnabled,
    'rivals': _rivals.map((r) => r.toJson()).toList(),
    'unlockedAchievements': _unlockedAchievements.toList(),
  };

  factory CareerManager.fromJson(Map<String, dynamic> json) => CareerManager(
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
    rivals: (json['rivals'] as List?)?.map((r) => RivalInfo.fromJson(r)).toList(),
    unlockedAchievements: (json['unlockedAchievements'] as List?)?.map((e) => e.toString()).toList(),
  );
}
