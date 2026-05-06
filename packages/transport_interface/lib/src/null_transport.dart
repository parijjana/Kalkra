import 'dart:async';
import 'itransport.dart';
import 'models.dart';

/// A local-only transport implementation for Solo mode.
class NullTransport implements IGameTransport {
  @override
  String get myId => 'solo';

  final _eventController = StreamController<GameEvent>.broadcast();

  @override
  Stream<GameEvent> get eventStream => _eventController.stream;

  @override
  Future<void> hostSession({required String playerName, Map<String, dynamic>? options}) async {
    _eventController.add(GameEvent(
      type: GameEventType.playerJoined,
      payload: PlayerInfo(id: 'solo', name: playerName, isHost: true).toJson(),
    ));
  }

  @override
  Future<void> joinSession({required String playerName, required String connectionInfo, Map<String, dynamic>? options}) async {
    // No-op
  }

  @override
  Future<void> sendEvent(GameEvent event) async {
    _eventController.add(event);
  }

  @override
  Future<void> kickPlayer(String playerId) async {
    // No-op for solo
  }

  @override
  Future<void> disconnect() async {
    await _eventController.close();
  }
}
