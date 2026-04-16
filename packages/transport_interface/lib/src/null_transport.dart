import 'dart:async';
import 'models.dart';
import 'itransport.dart';

/// A local-only transport implementation for Solo Practice mode.
class NullTransport implements IGameTransport {
  final _controller = StreamController<GameEvent>.broadcast();

  @override
  Stream<GameEvent> get eventStream => _controller.stream;

  @override
  Future<void> hostSession({required String playerName, Map<String, dynamic>? options}) async {
    _controller.add(GameEvent(
      type: GameEventType.playerJoined,
      payload: PlayerInfo(id: 'local-host', name: playerName, isHost: true).toJson(),
    ));
  }

  @override
  Future<void> joinSession({required String playerName, required String connectionInfo}) async {
    throw UnsupportedError('Cannot join a session in NullTransport. Use hostSession for solo play.');
  }

  @override
  Future<void> sendEvent(GameEvent event) async {
    // In NullTransport, we just pipe events back to the local listener.
    _controller.add(event);
  }

  @override
  Future<void> disconnect() async {
    await _controller.close();
  }
}
