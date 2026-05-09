import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('Reproduction: Scoring logic distance check', () {
    late ScoreKeeper scoreKeeper;

    setUp(() {
      scoreKeeper = ScoreKeeper();
    });

    test('Score should be 7 for target 100 and result 101 (distance 1)', () {
      final score = scoreKeeper.calculateScore(target: 100, result: 101);
      expect(score, 7, reason: 'Distance of 1 should yield 7 points regardless of direction');
    });

    test('Score should be 7 for target 100 and result 105 (distance 5)', () {
      final score = scoreKeeper.calculateScore(target: 100, result: 105);
      expect(score, 7, reason: 'Distance of 5 should yield 7 points regardless of direction');
    });

    test('Score should be 5 for target 100 and result 110 (distance 10)', () {
      final score = scoreKeeper.calculateScore(target: 100, result: 110);
      expect(score, 5, reason: 'Distance of 10 should yield 5 points regardless of direction');
    });

    test('Double or Nothing: Exact match returns 20', () {
      final score = scoreKeeper.calculateScore(
        target: 100, 
        result: 100, 
        jeopardy: JeopardyType.doubleOrNothing
      );
      expect(score, 20);
    });

    test('Double or Nothing: Result 101 (off by 1) returns 0', () {
      final score = scoreKeeper.calculateScore(
        target: 100, 
        result: 101, 
        jeopardy: JeopardyType.doubleOrNothing
      );
      expect(score, 0);
    });

    test('Double or Nothing: Result 99 (off by 1) returns 0', () {
      final score = scoreKeeper.calculateScore(
        target: 100, 
        result: 99, 
        jeopardy: JeopardyType.doubleOrNothing
      );
      expect(score, 0);
    });

    test('Allow negative intermediate results', () {
      final validator = SubmissionValidator();
      // (10 - 20) + 110 = 100
      final result = validator.validate('(10 - 20) + 110', [10, 20, 110]);
      expect(result.isValid, isTrue);
      expect(result.value, 100);
      expect(result.intermediateResults, contains(-10));
    });

    test('Allow fractional intermediate results (when enabled)', () {
      final validator = SubmissionValidator();
      // (10 / 4) * 40 = 100
      // 10/4 = 2.5
      final result = validator.validate('(10 / 4) * 40', [10, 4, 40], allowFractions: true);
      expect(result.isValid, isTrue);
      expect(result.value, 100);
      expect(result.intermediateResults, contains(2.5));
    });

    test('Block fractional intermediate results by default', () {
      final validator = SubmissionValidator();
      final result = validator.validate('10 / 4', [10, 4]);
      expect(result.isValid, isFalse);
      expect(result.error, contains('must be an integer'));
    });
  });
}
