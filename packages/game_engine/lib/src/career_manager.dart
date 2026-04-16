import 'elo_calculator.dart';

class RivalInfo {
  final String name;
  final int eloShift;
  final DateTime date;

  RivalInfo({required this.name, required this.eloShift, required this.date});

  Map<String, dynamic> toJson() => {
    'name': name,
    'eloShift': eloShift,
    'date': date.toIso8601String(),
  };

  factory RivalInfo.fromJson(Map<String, dynamic> json) => RivalInfo(
    name: json['name'],
    eloShift: json['eloShift'],
    date: DateTime.parse(json['date']),
  );
}

class CareerManager {
  int _elo;
  int _matchesWon;
  double _avgSpeedSeconds;
  double _avgAccuracy;
  int _roundsTracked;
  final List<RivalInfo> _rivals;

  CareerManager({
    int elo = 1200,
    int matchesWon = 0,
    double avgSpeedSeconds = 0.0,
    double avgAccuracy = 0.0,
    int roundsTracked = 0,
    List<RivalInfo>? rivals,
  }) : _elo = elo,
       _matchesWon = matchesWon,
       _avgSpeedSeconds = avgSpeedSeconds,
       _avgAccuracy = avgAccuracy,
       _roundsTracked = roundsTracked,
       _rivals = rivals ?? [];

  int get elo => _elo;
  int get matchesWon => _matchesWon;
  double get avgSpeedSeconds => _avgSpeedSeconds;
  double get avgAccuracy => _avgAccuracy;
  List<RivalInfo> get rivals => List.unmodifiable(_rivals);

  void recordRoundPerformance({required double secondsToSubmit, required int proximityToTarget}) {
    _avgSpeedSeconds = ((_avgSpeedSeconds * _roundsTracked) + secondsToSubmit) / (_roundsTracked + 1);
    _avgAccuracy = ((_avgAccuracy * _roundsTracked) + proximityToTarget) / (_roundsTracked + 1);
    _roundsTracked++;
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
    'elo': _elo,
    'matchesWon': _matchesWon,
    'avgSpeedSeconds': _avgSpeedSeconds,
    'avgAccuracy': _avgAccuracy,
    'roundsTracked': _roundsTracked,
    'rivals': _rivals.map((r) => r.toJson()).toList(),
  };

  factory CareerManager.fromJson(Map<String, dynamic> json) => CareerManager(
    elo: json['elo'],
    matchesWon: json['matchesWon'],
    avgSpeedSeconds: json['avgSpeedSeconds'],
    avgAccuracy: json['avgAccuracy'],
    roundsTracked: json['roundsTracked'],
    rivals: (json['rivals'] as List).map((r) => RivalInfo.fromJson(r)).toList(),
  );
}
