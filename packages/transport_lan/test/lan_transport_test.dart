import 'package:test/test.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import 'dart:async';

void main() {
  group('LanTransport Integration', () {
    late LanHostTransport host;
    late LanClientTransport client;

    setUp(() async {
      host = LanHostTransport();
      client = LanClientTransport();
    });

    tearDown(() async {
      await client.disconnect();
      await host.disconnect();
    });

    test('client can connect to host and receive join event', () async {
      await host.hostSession(playerName: 'HostAlice', options: {'port': 0});
      final port = host.port;

      final completer = Completer<GameEvent>();
      host.eventStream.listen((event) {
        if (event.payload['name'] == 'ClientBob') {
          completer.complete(event);
        }
      });
      
      await client.joinSession(
        playerName: 'ClientBob', 
        connectionInfo: 'ws://127.0.0.1:$port',
      );

      final result = await completer.future.timeout(const Duration(seconds: 5));
      expect(result.type, GameEventType.playerJoined);
      expect(result.payload['name'], 'ClientBob');
    });

    test('host can broadcast events to client', () async {
      await host.hostSession(playerName: 'HostAlice', options: {'port': 0});
      final port = host.port;
      
      final completer = Completer<GameEvent>();
      await client.joinSession(playerName: 'ClientBob', connectionInfo: 'ws://127.0.0.1:$port');
      
      client.eventStream.listen((event) {
        if (event.type == GameEventType.roundStarted) {
          completer.complete(event);
        }
      });

      // Allow connection to stabilize
      await Future.delayed(const Duration(milliseconds: 200));

      final event = GameEvent(type: GameEventType.roundStarted, payload: {'target': 100});
      await host.sendEvent(event);

      final result = await completer.future.timeout(const Duration(seconds: 5));
      expect(result.type, GameEventType.roundStarted);
      expect(result.payload['target'], 100);
    });
  });
}
