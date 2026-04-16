import 'package:test/test.dart';
import 'package:game_engine/src/score_keeper.dart';

void main() {
  group('ScoreKeeper', () {
    late ScoreKeeper scoreKeeper;

    setUp(() {
      scoreKeeper = ScoreKeeper();
    });

    test('exact match returns 10 points', () {
      expect(scoreKeeper.calculateScore(target: 100, result: 100), 10);
    });

    test('1 to 5 away returns 7 points', () {
      expect(scoreKeeper.calculateScore(target: 100, result: 101), 7);
      expect(scoreKeeper.calculateScore(target: 100, result: 95), 7);
    });

    test('6 to 10 away returns 5 points', () {
      expect(scoreKeeper.calculateScore(target: 100, result: 106), 5);
      expect(scoreKeeper.calculateScore(target: 100, result: 90), 5);
    });

    test('more than 10 away returns 0 points', () {
      expect(scoreKeeper.calculateScore(target: 100, result: 111), 0);
      expect(scoreKeeper.calculateScore(target: 100, result: 89), 0);
    });

    test('null result returns 0 points', () {
      expect(scoreKeeper.calculateScore(target: 100, result: null), 0);
    });
  });
}
