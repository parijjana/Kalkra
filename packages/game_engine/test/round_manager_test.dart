import 'package:test/test.dart';
import 'package:game_engine/src/round_manager.dart';
import 'package:game_engine/src/number_generator.dart';

void main() {
  group('RoundManager', () {
    late RoundManager roundManager;

    setUp(() {
      roundManager = RoundManager();
    });

    test('initial state is idle', () {
      expect(roundManager.state, RoundState.idle);
    });

    test('starts a new round and transitions to playing', () {
      roundManager.startRound(seed: 123, difficulty: Difficulty.easy);
      expect(roundManager.state, RoundState.playing);
      expect(roundManager.numbers.length, 4);
      expect(roundManager.target, isNotNull);

      roundManager.startRound(seed: 123, difficulty: Difficulty.medium);
      expect(roundManager.numbers.length, 6);
    });

    test('accepts submissions during playing state', () {
      roundManager.startRound(seed: 123);
      // Let's assume numbers are [1, 2, 3, 4, 5, 25] and target is something reachable.
      // For TDD, I'll just check if it records a submission.
      roundManager.submitExpression('1 + 2');
      expect(roundManager.submissions.length, 1);
    });

    test('fails submissions if not in playing state', () {
      expect(() => roundManager.submitExpression('1 + 2'), throwsStateError);
    });

    test('transitions to scoring state and evaluates results', () {
      roundManager.startRound(seed: 1);
      roundManager.submitExpression('1 + 1'); // Simple submission
      roundManager.endRound();
      expect(roundManager.state, RoundState.scoring);
      expect(roundManager.bestSolution, isNotNull);
    });

    test('completes a round', () {
      roundManager.startRound();
      roundManager.endRound();
      roundManager.completeRound();
      expect(roundManager.state, RoundState.completed);
    });

    test('starts a round with explicit data', () {
      final numbers = [1, 2, 3, 4, 5, 6];
      const target = 500;
      roundManager.startRoundWithData(numbers: numbers, target: target);
      
      expect(roundManager.state, RoundState.playing);
      expect(roundManager.numbers, equals(numbers));
      expect(roundManager.target, equals(target));
    });
  });
}
