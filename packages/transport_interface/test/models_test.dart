import 'package:test/test.dart';
import 'package:transport_interface/transport_interface.dart';

void main() {
  group('Transport Models', () {
    test('PlayerInfo serialization', () {
      final player = PlayerInfo(id: '1', name: 'Alice', isHost: true);
      final json = player.toJson();
      final fromJson = PlayerInfo.fromJson(json);
      
      expect(fromJson.id, player.id);
      expect(fromJson.name, player.name);
      expect(fromJson.isHost, player.isHost);
    });

    test('GameEvent serialization', () {
      final event = GameEvent(
        type: GameEventType.roundStarted,
        payload: {'target': 542, 'numbers': [1, 2, 3]},
      );
      final json = event.toJson();
      final fromJson = GameEvent.fromJson(json);
      
      expect(fromJson.type, GameEventType.roundStarted);
      expect(fromJson.payload['target'], 542);
    });
  });
}
