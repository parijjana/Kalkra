import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

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
      final data = MatchRoundData.mock(numbers: [1, 2, 3, 4]);
      roundManager.startRound(data: data);
      expect(roundManager.state, RoundState.playing);
      expect(roundManager.numbers.length, 4);
      expect(roundManager.target, isNotNull);
    });

    test('accepts submissions during playing state', () {
      roundManager.startRound(data: MatchRoundData.mock());
      roundManager.submitExpression('1 + 2');
      expect(roundManager.submissions.length, 1);
    });

    test('fails submissions if not in playing state', () {
      expect(() => roundManager.submitExpression('1 + 2'), throwsStateError);
    });

    test('transitions to scoring state', () {
      roundManager.startRound(data: MatchRoundData.mock());
      roundManager.submitExpression('1 + 1'); // Simple submission
      roundManager.endRound();
      expect(roundManager.state, RoundState.scoring);
    });

    test('completes a round', () {
      roundManager.startRound(data: MatchRoundData.mock());
      roundManager.endRound();
      roundManager.completeRound();
      expect(roundManager.state, RoundState.completed);
    });

    test('starts a round with explicit data', () {
      final numbers = [1, 2, 3, 4, 5, 6];
      const target = 500;
      roundManager.startRoundWithData(numbers: numbers, targets: [target]);
      
      expect(roundManager.state, RoundState.playing);
      expect(roundManager.numbers, equals(numbers));
      expect(roundManager.target, equals(target));
    });
  });
}
