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
  double _avgSpeedSeconds;
  double _avgAccuracy;
  int _roundsTracked;
  int _currentStreak;
  int _bestStreak;
  final List<RivalInfo> _rivals;

  CareerManager({
    String playerName = 'Guest',
    int elo = 1200,
    int matchesWon = 0,
    double avgSpeedSeconds = 0.0,
    double avgAccuracy = 0.0,
    int roundsTracked = 0,
    int currentStreak = 0,
    int bestStreak = 0,
    List<RivalInfo>? rivals,
  }) : _playerName = playerName,
       _elo = elo,
       _matchesWon = matchesWon,
       _avgSpeedSeconds = avgSpeedSeconds,
       _avgAccuracy = avgAccuracy,
       _roundsTracked = roundsTracked,
       _currentStreak = currentStreak,
       _bestStreak = bestStreak,
       _rivals = rivals ?? [];

  String get playerName => _playerName;
  int get elo => _elo;
  int get matchesWon => _matchesWon;
  double get avgSpeedSeconds => _avgSpeedSeconds;
  double get avgAccuracy => _avgAccuracy;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  List<RivalInfo> get rivals => List.unmodifiable(_rivals);

  void setPlayerName(String name) {
    _playerName = name;
  }

  void recordRoundPerformance({required double secondsToSubmit, required int proximityToTarget}) {
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
      name: 'Solo Practice',
      eloShift: proximityToTarget == 0 ? 10 : 0, // Visual indicator of success
      date: DateTime.now(),
      wasSolo: true,
    ));

    if (_rivals.length > 20) {
      _rivals.removeLast();
    }
  }

  /// Apply a pre-calculated Elo shift (received from host or calculated locally).
  void applyEloShift(int shift, String opponentName) {
    _elo += shift;
    if (shift > 0) _matchesWon++; // Simplified: positive shift means a "win" or good performance

    _rivals.insert(0, RivalInfo(
      name: opponentName,
      eloShift: shift,
      date: DateTime.now(),
    ));

    if (_rivals.length > 20) {
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
    'avgSpeedSeconds': _avgSpeedSeconds,
    'avgAccuracy': _avgAccuracy,
    'roundsTracked': _roundsTracked,
    'currentStreak': _currentStreak,
    'bestStreak': _bestStreak,
    'rivals': _rivals.map((r) => r.toJson()).toList(),
  };

  factory CareerManager.fromJson(Map<String, dynamic> json) => CareerManager(
    playerName: json['playerName'] ?? 'Guest',
    elo: json['elo'] ?? 1200,
    matchesWon: json['matchesWon'] ?? 0,
    avgSpeedSeconds: (json['avgSpeedSeconds'] ?? 0.0).toDouble(),
    avgAccuracy: (json['avgAccuracy'] ?? 0.0).toDouble(),
    roundsTracked: json['roundsTracked'] ?? 0,
    currentStreak: json['currentStreak'] ?? 0,
    bestStreak: json['bestStreak'] ?? 0,
    rivals: (json['rivals'] as List?)?.map((r) => RivalInfo.fromJson(r)).toList(),
  );
}
