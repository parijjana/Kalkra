import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('MatchManager', () {
    test('initializes with a set number of rounds', () {
      final match = MatchManager(totalRounds: 5);
      expect(match.totalRounds, 5);
      expect(match.currentRound, 1);
    });

    test('pre-generates match and increments round', () {
      final match = MatchManager(totalRounds: 3);
      match.generateMatch();
      
      expect(match.currentRoundData, isNotNull);
      expect(match.currentRound, 1);
      
      match.nextRound();
      expect(match.currentRound, 2);
      expect(match.currentRoundData, isNotNull);
      
      match.nextRound();
      expect(match.currentRound, 3);
    });

    test('pre-calculates jeopardy correctly', () {
      final match = MatchManager(totalRounds: 10, jeopardyEnabled: true, seed: 42);
      match.generateMatch();

      // Verify that at least some rounds have jeopardy in a long match
      bool foundJeopardy = false;
      for (int i = 0; i < 10; i++) {
        if (match.currentRoundData?.jeopardy != null) foundJeopardy = true;
        match.nextRound();
      }
      expect(foundJeopardy, isTrue);
    });

    test('isMatchOver returns true after final round', () {
      final match = MatchManager(totalRounds: 2);
      match.generateMatch();

      expect(match.isMatchOver, isFalse);
      match.nextRound(); // to R2
      expect(match.isMatchOver, isFalse);
      match.nextRound(); // to R3 (over)
      expect(match.isMatchOver, isTrue);
    });

    test('Jeopardy distribution: 10-round match has 2-3 events', () {
      final match = MatchManager(totalRounds: 10, jeopardyEnabled: true, seed: 100);
      match.generateMatch();
      
      int jCount = 0;
      for (int i = 0; i < 10; i++) {
        if (match.currentRoundData?.jeopardy != null) jCount++;
        match.nextRound();
      }
      expect(jCount, anyOf(2, 3), reason: '10-round match must have 2 or 3 jeopardy rounds');
    });

    test('Jeopardy distribution: Endless mode scales frequency', () {
      final match = MatchManager(gameMode: GameMode.endless, jeopardyEnabled: true, seed: 200);
      match.generateMatch(); // Generates first 10
      
      int block0Count = 0;
      for (int i = 0; i < 10; i++) {
        if (match.currentRoundData?.jeopardy != null) block0Count++;
        match.nextRound(); // Triggers refill at R9/10
      }
      expect(block0Count, equals(3), reason: 'Endless Block 0 must have exactly 3 jeopardy rounds');
      
      int block1Count = 0;
      for (int i = 0; i < 10; i++) {
        if (match.currentRoundData?.jeopardy != null) block1Count++;
        match.nextRound();
      }
      expect(block1Count, anyOf(4, 5), reason: 'Subsequent Endless blocks must have 4 or 5 jeopardy rounds');
    });
  });
}
