class PlayerSessionData {
  final String name;
  final int currentElo;
  bool isReady;
  int cumulativeScore;
  String? lastExpression;
  int? lastPoints;

  PlayerSessionData(this.name, {required this.currentElo, this.isReady = false, this.cumulativeScore = 0});
}

class SessionManager {
  final Map<String, PlayerSessionData> _players = {};

  Map<String, PlayerSessionData> get players => Map.unmodifiable(_players);

  bool get allReady => _players.isNotEmpty && _players.values.every((p) => p.isReady);

  void addPlayer(String id, String name, {int elo = 1200}) {
    String uniqueName = name;
    int counter = 2;
    
    final existingNames = _players.values.map((p) => p.name).toSet();
    
    while (existingNames.contains(uniqueName)) {
      uniqueName = '$name $counter';
      counter++;
    }

    _players[id] = PlayerSessionData(uniqueName, currentElo: elo);
  }

  void removePlayer(String id) {
    _players.remove(id);
  }

  void setPlayerReady(String id, bool ready) {
    _players[id]?.isReady = ready;
  }

  bool isPlayerReady(String id) {
    return _players[id]?.isReady ?? false;
  }

  void recordSubmission(String id, String expression, int points) {
    final player = _players[id];
    if (player != null) {
      player.lastExpression = expression;
      player.lastPoints = points;
      player.cumulativeScore += points;
    }
  }

  int getPlayerScore(String id) {
    return _players[id]?.cumulativeScore ?? 0;
  }

  void resetReadiness() {
    for (final player in _players.values) {
      player.isReady = false;
    }
  }

  void resetRoundData() {
    for (final player in _players.values) {
      player.lastExpression = null;
      player.lastPoints = null;
    }
  }

  void resetScores() {
    for (final player in _players.values) {
      player.cumulativeScore = 0;
    }
  }
}
