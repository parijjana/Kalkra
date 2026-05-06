enum GameEventType {
  playerJoined,
  playerLeft,
  playerReady,
  lobbyUpdate,     // Sync full lobby state (teams, ready status)
  teamAssignment,  // Host assigns a player to a team
  teamRename,      // New: Host renames a team
  hostStartedMatch, // Host triggers game start from lobby
  roundStarted,
  roundEnded,
  roundResults, 
  submissionReceived,
  matchResults, 
  matchEnded,
  kicked, 
  heartbeat,       // New: Periodic sync from host to verify connection
  error
}

class PlayerInfo {
  final String id;
  final String name;
  final bool isHost;
  final int currentElo;
  final String? deviceId; 
  final int teamId;
  final bool isReady;
  final String? lastExpression;
  final int cumulativeScore;
  final String? lobbySecret; // Authorization secret from QR code
  final bool isSpectator;    // Role identifier for host-only mode

  PlayerInfo({
    required this.id, 
    required this.name, 
    this.isHost = false,
    this.currentElo = 1200,
    this.deviceId,
    this.teamId = 0,
    this.isReady = false,
    this.lastExpression,
    this.cumulativeScore = 0,
    this.lobbySecret,
    this.isSpectator = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isHost': isHost,
    'currentElo': currentElo,
    'deviceId': deviceId,
    'teamId': teamId,
    'isReady': isReady,
    'lastExpression': lastExpression,
    'cumulativeScore': cumulativeScore,
    'lobbySecret': lobbySecret,
    'isSpectator': isSpectator,
  };

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => PlayerInfo(
    id: json['id'],
    name: json['name'],
    isHost: json['isHost'] ?? false,
    currentElo: json['currentElo'] ?? 1200,
    deviceId: json['deviceId'],
    teamId: json['teamId'] ?? 0,
    isReady: json['isReady'] ?? false,
    lastExpression: json['lastExpression'],
    cumulativeScore: json['cumulativeScore'] ?? 0,
    lobbySecret: json['lobbySecret'],
    isSpectator: json['isSpectator'] ?? false,
  );
}

class GameEvent {
  final GameEventType type;
  final Map<String, dynamic> payload;
  final int sequenceNumber; // New: For replay protection

  GameEvent({
    required this.type, 
    required this.payload, 
    this.sequenceNumber = 0
  });

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'payload': payload,
    'seq': sequenceNumber,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    type: GameEventType.values[json['type']],
    payload: Map<String, dynamic>.from(json['payload']),
    sequenceNumber: json['seq'] ?? 0,
  );
}
