import 'package:test/test.dart';
import 'package:game_engine/src/match_manager.dart';
import 'package:game_engine/src/number_generator.dart';

void main() {
  group('MatchManager', () {
    test('initializes with a set number of rounds', () {
      final match = MatchManager(totalRounds: 5);
      expect(match.totalRounds, 5);
      expect(match.currentRound, 1);
    });

    test('increments round and updates difficulty/jeopardy', () {
      final match = MatchManager(totalRounds: 3);
      expect(match.currentDifficulty, Difficulty.easy);
      
      match.nextRound();
      expect(match.currentRound, 2);
      expect(match.currentDifficulty, Difficulty.medium);
      
      match.nextRound();
      expect(match.currentRound, 3);
      expect(match.currentDifficulty, Difficulty.hard);
    });

    test('assigns random jeopardy in later rounds', () {
      final match = MatchManager(totalRounds: 5, seed: 42);
      // Round 1 usually no jeopardy
      expect(match.activeJeopardy, isNull);
      
      // Move to rounds where jeopardy might trigger
      match.nextRound(); // R2
      match.nextRound(); // R3
      expect(match.activeJeopardy, isNotNull);
    });

    test('isMatchOver returns true after final round', () {
      final match = MatchManager(totalRounds: 2);
      expect(match.isMatchOver, isFalse);
      match.nextRound();
      expect(match.isMatchOver, isFalse);
      match.nextRound();
      expect(match.isMatchOver, isTrue);
    });
  });
}
