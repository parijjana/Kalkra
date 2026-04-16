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

    test('hostSession applies elo and port options', () async {
      final completer = Completer<GameEvent>();
      host.eventStream.listen((event) {
        if (!completer.isCompleted) completer.complete(event);
      });

      await host.hostSession(playerName: 'HostAlice', options: {'port': 0, 'elo': 1600});
      expect(host.port, greaterThan(0));
      
      final event = await completer.future.timeout(const Duration(seconds: 5));
      final info = PlayerInfo.fromJson(event.payload);
      expect(info.name, 'HostAlice');
      expect(info.currentElo, 1600);
    });

    test('client can connect to host and receive join event with full info', () async {
      await host.hostSession(playerName: 'HostAlice', options: {'port': 0});
      final port = host.port;

      final completer = Completer<GameEvent>();
      host.eventStream.listen((event) {
        if (event.type == GameEventType.playerJoined) {
          final info = PlayerInfo.fromJson(event.payload);
          if (info.name == 'ClientBob') {
            completer.complete(event);
          }
        }
      });
      
      await client.joinSession(
        playerName: 'ClientBob', 
        connectionInfo: 'ws://127.0.0.1:$port',
        options: {'elo': 1300},
      );

      final result = await completer.future.timeout(const Duration(seconds: 5));
      final playerInfo = PlayerInfo.fromJson(result.payload);
      expect(playerInfo.name, 'ClientBob');
      expect(playerInfo.currentElo, 1300);
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
