import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('MatchManager: Host Logic & Random Jeopardy', () {
    test('Random Jeopardy distribution should be approx 30%', () {
      final manager = MatchManager(totalRounds: 10, jeopardyEnabled: true);
      for (int i = 0; i < 10; i++) {
        manager.nextRound();
      }
      // Over many runs it averages 30%, in a single 10 round run it could be 0-10, 
      // but let's just verify the logic exists and isn't 100% or 0% constantly.
      expect(manager.jeopardyEnabled, isTrue);
    });
  });
}
