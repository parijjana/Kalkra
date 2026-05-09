import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('Tier 3: Constraints & Pools', () {
    late NumberGenerator numGen;
    late ScoreKeeper scoreKeeper;

    setUp(() {
      numGen = NumberGenerator();
      scoreKeeper = ScoreKeeper();
    });

    test('NumberGenerator: PoolType.primesOnly produces only primes', () {
      final pool = numGen.generatePool(poolType: PoolType.primesOnly, seed: 42);
      final primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47];
      for (final n in pool) {
        expect(primes.contains(n), isTrue, reason: '$n is not a prime');
      }
    });

    test('NumberGenerator: PoolType.smallOnly produces numbers <= 10', () {
      final pool = numGen.generatePool(poolType: PoolType.smallOnly, seed: 42);
      for (final n in pool) {
        expect(n, lessThanOrEqualTo(10));
      }
    });

    test('OperationsBlackoutConstraint: Correcty bans operators', () {
      final constraint = OperationsBlackoutConstraint(['*', '/']);
      
      // Valid: only uses +
      expect(constraint.validate([1, 2], ['+']), isTrue);
      
      // Invalid: uses banned *
      expect(constraint.validate([1, 2], ['*', '+']), isFalse);
    });

    test('ScoreKeeper: Dual Target scoring picks closest match', () {
      final targets = [100, 500];
      
      // Exact match for one
      expect(scoreKeeper.calculateDualTargetScore(targets: targets, result: 100), equals(10));
      expect(scoreKeeper.calculateDualTargetScore(targets: targets, result: 500), equals(10));
      
      // Proximity to 100 (98 is 2 away -> 7 pts)
      expect(scoreKeeper.calculateDualTargetScore(targets: targets, result: 98), equals(7));
      
      // Proximity to 500 (505 is 5 away -> 7 pts)
      expect(scoreKeeper.calculateDualTargetScore(targets: targets, result: 505), equals(7));
      
      // Far from both
      expect(scoreKeeper.calculateDualTargetScore(targets: targets, result: 300), equals(0));
    });

    test('RoundManager: Applies reward bumps for Tier 3', () {
      final round = RoundManager();
      round.startRoundWithData(
        numbers: [10, 10],
        targets: [20],
        config: RoundConfig.mandatoryNumber, // rewardBump = 3
      );
      
      // Exact match: 10 + 3 = 13
      expect(round.calculatePoints('10 + 10'), equals(13));
    });
  });
}
