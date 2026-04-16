enum GameEventType {
  playerJoined,
  playerLeft,
  playerReady,
  roundStarted,
  roundEnded,
  roundResults, // New
  submissionReceived,
  matchResults, // New
  matchEnded,
  error
}

class PlayerInfo {
  final String id;
  final String name;
  final bool isHost;
  final int currentElo;
  final Map<String, dynamic> stats;

  PlayerInfo({
    required this.id, 
    required this.name, 
    this.isHost = false,
    this.currentElo = 1200,
    this.stats = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isHost': isHost,
    'currentElo': currentElo,
    'stats': stats,
  };

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => PlayerInfo(
    id: json['id'],
    name: json['name'],
    isHost: json['isHost'] ?? false,
    currentElo: json['currentElo'] ?? 1200,
    stats: Map<String, dynamic>.from(json['stats'] ?? {}),
  );
}

class GameEvent {
  final GameEventType type;
  final Map<String, dynamic> payload;

  GameEvent({required this.type, required this.payload});

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'payload': payload,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    type: GameEventType.values[json['type']],
    payload: Map<String, dynamic>.from(json['payload']),
  );
}
