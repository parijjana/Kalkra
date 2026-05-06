class PlayerSessionData {
  final String name;
  final int currentElo;
  final String? deviceId;
  final bool isHost;
  bool isReady;
  int teamId; // 0 = Unassigned, 1-4 = Teams
  int cumulativeScore;
  String? lastExpression;
  int? lastPoints;

  PlayerSessionData(this.name, {
    required this.currentElo, 
    this.deviceId, 
    this.isHost = false, 
    this.isReady = false, 
    this.teamId = 0,
    this.cumulativeScore = 0
  });

  Map<String, dynamic> toLobbyJson(String id) => {
    'id': id,
    'name': name,
    'isReady': isReady,
    'teamId': teamId,
    'elo': currentElo,
    'isHost': isHost,
  };
}

class MatchRecord {
  final DateTime date;
  final int winnerTeamId;
  final String winnerName;
  final Map<int, int> teamScores;

  MatchRecord({
    required this.date,
    required this.winnerTeamId,
    required this.winnerName,
    required this.teamScores,
  });
}

class SessionManager {
  final Map<String, PlayerSessionData> _players = {};
  final Map<int, int> _teamScores = {1: 0, 2: 0, 3: 0, 4: 0};
  final Map<int, String> _teamNames = {1: 'Team 1', 2: 'Team 2', 3: 'Team 3', 4: 'Team 4'};

  // Session History
  final List<MatchRecord> _matchHistory = [];
  final Map<int, int> _sessionTeamScores = {1: 0, 2: 0, 3: 0, 4: 0};

  Map<String, PlayerSessionData> get players => Map.unmodifiable(_players);
  Map<int, int> get teamScores => Map.unmodifiable(_teamScores);
  Map<int, String> get teamNames => Map.unmodifiable(_teamNames);
  List<MatchRecord> get matchHistory => List.unmodifiable(_matchHistory);
  Map<int, int> get sessionTeamScores => Map.unmodifiable(_sessionTeamScores);

  void renameTeam(int teamId, String name) {
    if (_teamNames.containsKey(teamId)) {
      _teamNames[teamId] = name;
    }
  }

  void recordMatchOutcome(int winnerTeamId) {
    _matchHistory.add(MatchRecord(
      date: DateTime.now(),
      winnerTeamId: winnerTeamId,
      winnerName: _teamNames[winnerTeamId] ?? 'Unknown',
      teamScores: Map.from(_teamScores),
    ));

    for (var entry in _teamScores.entries) {
      _sessionTeamScores[entry.key] = (_sessionTeamScores[entry.key] ?? 0) + entry.value;
    }
  }

  void syncSessionHistory({required List history, required Map<String, dynamic> totalScores}) {
    _matchHistory.clear();
    for (final m in history) {
      _matchHistory.add(MatchRecord(
        date: DateTime.parse(m['date']),
        winnerTeamId: m['winnerTeamId'],
        winnerName: m['winnerName'],
        teamScores: Map<String, dynamic>.from(m['teamScores']).map((k, v) => MapEntry(int.parse(k), v as int)),
      ));
    }
    _sessionTeamScores.clear();
    totalScores.forEach((k, v) {
      _sessionTeamScores[int.parse(k)] = v as int;
    });
  }
  /// Returns true if all players assigned to a team (teamId > 0) are ready.
  /// Unassigned players do not block the start but are ignored during match start.
  bool get allAssignedReady {
    final assignedPlayers = _players.values.where((p) => p.teamId > 0);
    if (assignedPlayers.isEmpty) return false;
    return assignedPlayers.every((p) => p.isReady);
  }

  /// Returns true if all players assigned to a team (teamId > 0) have submitted an expression.
  bool get allAssignedSubmitted {
    final assignedPlayers = _players.values.where((p) => p.teamId > 0);
    if (assignedPlayers.isEmpty) return false;
    return assignedPlayers.every((p) => p.lastExpression != null);
  }

  void addPlayer(String id, String name, {int elo = 1200, String? deviceId, bool isHost = false}) {
    if (_players.containsKey(id)) {
      final existing = _players[id]!;
      if (existing.name == name) {
        _players[id] = PlayerSessionData(
          name, 
          currentElo: elo, 
          deviceId: deviceId, 
          isHost: isHost,
          isReady: existing.isReady,
          teamId: existing.teamId,
          cumulativeScore: existing.cumulativeScore
        );
        return;
      }
    }

    String uniqueName = name;
    int counter = 2;
    final otherPlayerNames = _players.entries.where((e) => e.key != id).map((e) => e.value.name).toSet();
    while (otherPlayerNames.contains(uniqueName)) {
      uniqueName = '$name $counter';
      counter++;
    }

    if (_players.containsKey(id)) {
      final existing = _players[id]!;
      _players[id] = PlayerSessionData(
        uniqueName, 
        currentElo: elo, 
        deviceId: deviceId, 
        isHost: isHost,
        isReady: existing.isReady,
        teamId: existing.teamId,
        cumulativeScore: existing.cumulativeScore
      );
    } else {
      _players[id] = PlayerSessionData(uniqueName, currentElo: elo, deviceId: deviceId, isHost: isHost);
    }
  }

  void removePlayer(String id) {
    _players.remove(id);
  }

  void setPlayerReady(String id, bool ready) {
    if (_players.containsKey(id)) {
      _players[id]?.isReady = ready;
    }
  }

  void assignTeam(String id, int teamId) {
    if (teamId < 0 || teamId > 4) return;
    if (_players.containsKey(id)) {
      _players[id]?.teamId = teamId;
    }
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

  void awardTeamPoints(int teamId, int points) {
    if (_teamScores.containsKey(teamId)) {
      _teamScores[teamId] = (_teamScores[teamId] ?? 0) + points;
    }
  }

  int getPlayerScore(String id) {
    return _players[id]?.cumulativeScore ?? 0;
  }

  int getTeamScore(int teamId) {
    return _teamScores[teamId] ?? 0;
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
    _teamScores.updateAll((key, value) => 0);
  }

  List<Map<String, dynamic>> getLobbyState() {
    return _players.entries.map((e) => e.value.toLobbyJson(e.key)).toList();
  }

  Map<String, String> getTeamNames() {
    return _teamNames.map((k, v) => MapEntry(k.toString(), v));
  }

  void syncLobbyState({required List players, required Map<String, dynamic> names}) {
    for (final data in players) {
      final id = data['id'];
      addPlayer(id, data['name'], elo: data['elo'], isHost: data['isHost']);
      assignTeam(id, data['teamId']);
      setPlayerReady(id, data['isReady']);
    }
    names.forEach((k, v) {
      _teamNames[int.parse(k)] = v.toString();
    });
  }
}
