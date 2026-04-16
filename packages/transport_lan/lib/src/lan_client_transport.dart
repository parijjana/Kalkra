import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:transport_interface/transport_interface.dart';

class LanClientTransport implements IGameTransport {
  final _eventController = StreamController<GameEvent>.broadcast();
  WebSocketChannel? _channel;

  @override
  Stream<GameEvent> get eventStream => _eventController.stream;

  @override
  Future<void> hostSession({required String playerName, Map<String, dynamic>? options}) async {
    throw UnsupportedError('Use LanHostTransport to host a session.');
  }

  @override
  Future<void> joinSession({required String playerName, required String connectionInfo, Map<String, dynamic>? options}) async {
    final elo = options?['elo'] ?? 1200;
    final uri = Uri.parse(connectionInfo);
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      final event = GameEvent.fromJson(data);
      _eventController.add(event);
    });

    // Send join event to host with full info
    await sendEvent(GameEvent(
      type: GameEventType.playerJoined,
      payload: PlayerInfo(
        id: 'client-${DateTime.now().millisecondsSinceEpoch}', 
        name: playerName,
        currentElo: elo,
      ).toJson(),
    ));
  }

  @override
  Future<void> sendEvent(GameEvent event) async {
    if (_channel == null) return;
    final message = jsonEncode(event.toJson());
    _channel!.sink.add(message);
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _eventController.close();
  }
}
