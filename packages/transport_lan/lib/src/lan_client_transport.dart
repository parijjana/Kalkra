import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:transport_interface/transport_interface.dart';
import 'crypto_util.dart';

class LanClientTransport implements IGameTransport {
  String? _myId;
  @override
  String get myId => _myId ?? 'me';

  final _eventController = StreamController<GameEvent>.broadcast();
  WebSocketChannel? _channel;
  Timer? _heartbeatMonitor;
  String? _lobbySecret;

  @override
  Stream<GameEvent> get eventStream => _eventController.stream;

  @override
  Future<void> hostSession({required String playerName, Map<String, dynamic>? options}) async {
    throw UnsupportedError('Use LanHostTransport to host a session.');
  }

  @override
  Future<void> joinSession({required String playerName, required String connectionInfo, Map<String, dynamic>? options}) async {
    final elo = options?['elo'] ?? 1200;
    final deviceId = options?['deviceId'];
    
    // Parse connection info: expected "ws://ip:port?secret=XXXX"
    final uri = Uri.parse(connectionInfo);
    _lobbySecret = uri.queryParameters['secret'];
    
    if (_lobbySecret == null) {
      throw Exception('Missing encryption secret in connection info.');
    }

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((message) {
      try {
        _resetHeartbeatMonitor();
        // Decrypt incoming message
        final decrypted = CryptoUtil.decryptMessage(message as String, _lobbySecret!);
        final data = jsonDecode(decrypted);
        final event = GameEvent.fromJson(data);
        _eventController.add(event);
      } catch (e) {
        // Decryption failed -> unauthorized or malformed
        _eventController.add(GameEvent(
          type: GameEventType.error,
          payload: {'message': 'Decryption error. Connection is insecure or key is invalid.'},
        ));
        disconnect();
      }
    }, onDone: () {
      _heartbeatMonitor?.cancel();
      _eventController.add(GameEvent(
        type: GameEventType.error,
        payload: {'message': 'Connection to host lost.'},
      ));
    }, onError: (e) {
      _heartbeatMonitor?.cancel();
      _eventController.add(GameEvent(
        type: GameEventType.error,
        payload: {'message': 'Network error: $e'},
      ));
    });

    _resetHeartbeatMonitor();

    // Send join event to host with full info including the secret
    final id = deviceId != null ? 'client-$deviceId' : 'client-${DateTime.now().millisecondsSinceEpoch}';
    _myId = id;
    
    await sendEvent(GameEvent(
      type: GameEventType.playerJoined,
      payload: PlayerInfo(
        id: id, 
        name: playerName,
        currentElo: elo,
        deviceId: deviceId,
      ).toJson(),
    ));
  }

  void _resetHeartbeatMonitor() {
    _heartbeatMonitor?.cancel();
    _heartbeatMonitor = Timer(const Duration(seconds: 6), () {
      _eventController.add(GameEvent(
        type: GameEventType.error,
        payload: {'message': 'Host heartbeat lost. Returning to menu.'},
      ));
    });
  }

  int _outboundSequence = 0;

  @override
  Future<void> sendEvent(GameEvent event) async {
    if (_channel == null || _lobbySecret == null) return;
    
    // Add sequence number to outbound event
    final eventWithSeq = GameEvent(
      type: event.type, 
      payload: event.payload, 
      sequenceNumber: _outboundSequence++
    );
    
    final plainText = jsonEncode(eventWithSeq.toJson());
    final encrypted = CryptoUtil.encryptMessage(plainText, _lobbySecret!);
    
    _channel!.sink.add(encrypted);
  }

  @override
  Future<void> kickPlayer(String playerId) async {
    throw UnsupportedError('Only hosts can kick players.');
  }

  @override
  Future<void> disconnect() async {
    _heartbeatMonitor?.cancel();
    await _channel?.sink.close();
    await _eventController.close();
  }
}
