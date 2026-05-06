import 'models.dart';

abstract class IGameTransport {
  /// The unique identifier for the current device in the session.
  String get myId;

  /// Stream of events coming from the transport layer (network or local).
  Stream<GameEvent> get eventStream;

  /// Starts hosting a session.
  Future<void> hostSession({required String playerName, Map<String, dynamic>? options});

  /// Joins an existing session.
  Future<void> joinSession({required String playerName, required String connectionInfo, Map<String, dynamic>? options});

  /// Sends an event to all other players (if host) or to the host (if client).
  Future<void> sendEvent(GameEvent event);

  /// Forcefully removes a player from the session (Host only).
  Future<void> kickPlayer(String playerId);

  /// Disconnects and cleans up.
  Future<void> disconnect();
}
