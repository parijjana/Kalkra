import 'package:test/test.dart';
import 'package:transport_interface/transport_interface.dart';

void main() {
  group('Transport Models', () {
    test('PlayerInfo serialization with full data', () {
      final player = PlayerInfo(
        id: '1', 
        name: 'Alice', 
        isHost: true, 
        currentElo: 1500,
        stats: {'wins': 5},
      );
      final json = player.toJson();
      final fromJson = PlayerInfo.fromJson(json);
      
      expect(fromJson.id, player.id);
      expect(fromJson.name, player.name);
      expect(fromJson.isHost, player.isHost);
      expect(fromJson.currentElo, 1500);
      expect(fromJson.stats['wins'], 5);
    });

    test('PlayerInfo handles missing fields gracefully', () {
      final json = {'id': '2', 'name': 'Bob'};
      final player = PlayerInfo.fromJson(json);
      
      expect(player.id, '2');
      expect(player.name, 'Bob');
      expect(player.isHost, false); // Default
      expect(player.currentElo, 1200); // Default
      expect(player.stats, isEmpty); // Default
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
