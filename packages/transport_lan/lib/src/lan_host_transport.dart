import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:transport_interface/transport_interface.dart';

class LanHostTransport implements IGameTransport {
  final _eventController = StreamController<GameEvent>.broadcast();
  final List<WebSocketChannel> _clients = [];
  HttpServer? _server;
  int? _port;

  @override
  Stream<GameEvent> get eventStream => _eventController.stream;

  int get port => _port ?? 0;

  @override
  Future<void> hostSession({required String playerName, Map<String, dynamic>? options}) async {
    final requestedPort = options?['port'] ?? 8080;
    
    final handler = webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      
      webSocket.stream.listen((message) {
        final data = jsonDecode(message);
        final event = GameEvent.fromJson(data);
        
        if (event.type == GameEventType.playerJoined) {
           // We add the client channel to the payload for internal tracking if needed
           // but for now we just emit the event
        }
        
        _eventController.add(event);
      }, onDone: () {
        _clients.remove(webSocket);
      });
    });

    _server = await io.serve(handler, InternetAddress.loopbackIPv4, requestedPort);
    _port = _server!.port;
    
    // Emit host join event
    _eventController.add(GameEvent(
      type: GameEventType.playerJoined,
      payload: PlayerInfo(id: 'host', name: playerName, isHost: true).toJson(),
    ));
  }

  @override
  Future<void> joinSession({required String playerName, required String connectionInfo}) async {
    throw UnsupportedError('Use LanClientTransport to join a session.');
  }

  @override
  Future<void> sendEvent(GameEvent event) async {
    final message = jsonEncode(event.toJson());
    for (final client in _clients) {
      client.sink.add(message);
    }
    // Also emit locally for the host UI
    _eventController.add(event);
  }

  @override
  Future<void> disconnect() async {
    final clientsCopy = List<WebSocketChannel>.from(_clients);
    for (final client in clientsCopy) {
      await client.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    await _eventController.close();
  }
}
