import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nsd/nsd.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:gatekeeper_rate_limit/gatekeeper_rate_limit.dart';
import 'crypto_util.dart';

class LanHostTransport implements IGameTransport {
  @override
  String get myId => 'host';

  final _eventController = StreamController<GameEvent>.broadcast();
  final Map<String, WebSocketChannel> _clientMap = {}; 
  final Map<String, int> _clientSequenceMap = {}; // New: Track sequence numbers
  
  final RateLimiter _rateLimiter = RateLimiter(capacity: 10, refillRatePerSecond: 5);
  
  HttpServer? _server;
  Registration? _registration;
  int? _port;
  Set<String> _bannedDeviceIds = {};
  Timer? _heartbeatTimer;
  String? _lobbySecret;

  @override
  Stream<GameEvent> get eventStream => _eventController.stream;

  int get port => _port ?? 0;
  String? get lobbySecret => _lobbySecret;

  @override
  Future<void> hostSession({required String playerName, Map<String, dynamic>? options}) async {
    final requestedPort = options?['port'] ?? 8080;
    final elo = options?['elo'] ?? 1200;
    final isSpectator = options?['isSpectator'] ?? false;
    final bannedIds = options?['bannedDeviceIds'] as List<String>? ?? [];
    _bannedDeviceIds = bannedIds.toSet();
    
    // Generate a strong random key for this session
    _lobbySecret = CryptoUtil.generateSecureKey();
    
    final handler = webSocketHandler((WebSocketChannel webSocket) {
      String? currentClientId;

      webSocket.stream.listen((message) {
        try {
          // 1. Rate Limiting Check (DoS Protection)
          // Note: In shelf, getting remote address requires extra setup, 
          // we'll use currentClientId or a unique transport-level ID for now.
          final limitId = currentClientId ?? "anonymous-${webSocket.hashCode}";
          final rateRes = _rateLimiter.consume(limitId);
          if (!rateRes.allowed) return; // Drop packet silently

          // 2. Decrypt incoming message
          final decrypted = CryptoUtil.decryptMessage(message as String, _lobbySecret!);
          final data = jsonDecode(decrypted);
          final event = GameEvent.fromJson(data);

          // 3. Replay Protection (Sequence Number Check)
          if (currentClientId != null) {
             final lastSeq = _clientSequenceMap[currentClientId] ?? -1;
             if (event.sequenceNumber <= lastSeq) {
                // Replay detected!
                return; 
             }
             _clientSequenceMap[currentClientId!] = event.sequenceNumber;
          }

          // 4. Inject sender ID for client-originated events
          final payloadWithId = Map<String, dynamic>.from(event.payload);
          if (currentClientId != null) {
            payloadWithId['playerId'] = currentClientId;
          }
          final injectedEvent = GameEvent(
            type: event.type, 
            payload: payloadWithId, 
            sequenceNumber: event.sequenceNumber
          );

          if (injectedEvent.type == GameEventType.playerJoined) {
            final player = PlayerInfo.fromJson(injectedEvent.payload);
            
            // Validation: Ban Check (Secret is verified by successful decryption)
            if (player.deviceId != null && _bannedDeviceIds.contains(player.deviceId)) {
              _sendEncryptedToClient(webSocket, GameEvent(
                type: GameEventType.error,
                payload: {'message': 'You have been banned from this host.'},
              ));
              webSocket.sink.close();
              return;
            }

            currentClientId = player.id;
            _clientMap[player.id] = webSocket;
          }

          _eventController.add(injectedEvent);
        } catch (e) {
          // Decryption failure or invalid JSON -> unauthorized
          webSocket.sink.close();
        }
      }, onDone: () {
        if (currentClientId != null) {
          _clientMap.remove(currentClientId);
          _clientSequenceMap.remove(currentClientId);
          _eventController.add(GameEvent(
            type: GameEventType.playerLeft,
            payload: {'playerId': currentClientId},
          ));
        }
      });
    });

    _server = await io.serve(handler, InternetAddress.anyIPv4, requestedPort);
    _port = _server!.port;

    _registration = await register(Service(
      name: "$playerName's Arena",
      type: '_kalkra._tcp',
      port: _port,
      txt: {
        'hostName': Uint8List.fromList(utf8.encode(playerName)),
        'elo': Uint8List.fromList(utf8.encode(elo.toString())),
      },
    ));

    // Start periodic heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      sendEvent(GameEvent(type: GameEventType.heartbeat, payload: {}));
    });
    
    if (!isSpectator) {
      _eventController.add(GameEvent(
        type: GameEventType.playerJoined,
        payload: PlayerInfo(id: 'host', name: playerName, isHost: true, currentElo: elo).toJson(),
      ));
    }
  }

  @override
  Future<void> joinSession({required String playerName, required String connectionInfo, Map<String, dynamic>? options}) async {
    throw UnsupportedError('Use LanClientTransport to join a session.');
  }

  @override
  Future<void> sendEvent(GameEvent event) async {
    if (_lobbySecret == null) return;
    
    final plainText = jsonEncode(event.toJson());
    final encrypted = CryptoUtil.encryptMessage(plainText, _lobbySecret!);
    
    for (final client in _clientMap.values) {
      client.sink.add(encrypted);
    }
    _eventController.add(event);
  }

  void _sendEncryptedToClient(WebSocketChannel channel, GameEvent event) {
    if (_lobbySecret == null) return;
    final plainText = jsonEncode(event.toJson());
    final encrypted = CryptoUtil.encryptMessage(plainText, _lobbySecret!);
    channel.sink.add(encrypted);
  }

  @override
  Future<void> kickPlayer(String playerId) async {
    final channel = _clientMap[playerId];
    if (channel != null) {
      _sendEncryptedToClient(channel, GameEvent(
        type: GameEventType.kicked,
        payload: {'message': 'You have been kicked by the host.'},
      ));
      await channel.sink.close();
      _clientMap.remove(playerId);
    }
  }

  @override
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    final clientsCopy = List<WebSocketChannel>.from(_clientMap.values);
    for (final client in clientsCopy) {
      await client.sink.close();
    }
    _clientMap.clear();
    if (_registration != null) await unregister(_registration!);
    await _server?.close(force: true);
    await _eventController.close();
  }
}
