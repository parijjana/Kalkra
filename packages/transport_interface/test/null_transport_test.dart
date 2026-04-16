import 'package:test/test.dart';
import 'package:transport_interface/transport_interface.dart';

void main() {
  group('NullTransport', () {
    late NullTransport transport;

    setUp(() {
      transport = NullTransport();
    });

    test('hostSession emits playerJoined event', () async {
      final events = transport.eventStream.take(1).toList();
      await transport.hostSession(playerName: 'Alice');
      
      final results = await events;
      expect(results.first.type, GameEventType.playerJoined);
      expect(results.first.payload['name'], 'Alice');
    });

    test('sendEvent re-emits the same event', () async {
      final event = GameEvent(type: GameEventType.roundStarted, payload: {'test': 123});
      final events = transport.eventStream.skip(1).take(1).toList(); // Skip join event
      
      await transport.hostSession(playerName: 'Alice');
      await transport.sendEvent(event);
      
      final results = await events;
      expect(results.first.type, GameEventType.roundStarted);
      expect(results.first.payload['test'], 123);
    });
  });
}
