import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('Constraint-Aware Generation', () {
    late TargetGenerator targetGen;
    final pool = [1, 2, 3];

    setUp(() {
      targetGen = TargetGenerator();
    });

    test('generates reachable target with restricted operators', () {
      // With [1, 2, 3] and only '+', targets should be 3, 4, 5, 6
      final target = targetGen.generateReachableTarget(
        pool: pool,
        allowedOperators: ['+'],
      );
      
      expect([1, 2, 3, 4, 5, 6], contains(target));
      
      // Verify with solver
      final solver = SolverEngine();
      final result = solver.solve(pool, target, allowedOperators: ['+']);
      expect(result.foundExact, isTrue);
    });

    test('generates targets for Two Targets mode that are both reachable', () {
      final targets = targetGen.generateReachableTargets(
        count: 2,
        pool: pool,
        allowedOperators: ['+'],
      );
      
      expect(targets.length, 2);
      final solver = SolverEngine();
      for (final t in targets) {
        expect(solver.solve(pool, t, allowedOperators: ['+']).foundExact, isTrue);
      }
    });

    test('Tunnel Vision: target persists while pool changes', () {
      final round = RoundManager();
      
      // Round 1: Standard
      final data1 = MatchRoundData.mock(numbers: [1, 2, 3], targets: [6]);
      round.startRound(data: data1);
      final firstTarget = round.target!;
      final firstPool = List<int>.from(round.numbers);
      
      // Round 2: Tunnel Vision (persistent target)
      final data2 = MatchRoundData.mock(
        numbers: [4, 5, 1], // verified solvable for 6
        targets: [firstTarget],
        config: RoundConfig.tunnelVision,
      );
      round.startRound(data: data2);
      
      expect(round.target, equals(firstTarget), reason: 'Target should persist in Tunnel Vision');
      expect(round.numbers, isNot(equals(firstPool)), reason: 'Pool should be regenerated');
      
      // Verify reachability
      final solver = SolverEngine();
      expect(solver.solve(round.numbers, round.target!).foundExact, isTrue, reason: 'New pool must reach old target');
    });
  });

  group('Expression Deduplication (Canonical Form)', () {
    late SubmissionValidator validator;

    setUp(() {
      validator = SubmissionValidator();
    });

    test('canonical form ignores redundant brackets', () {
      final f1 = validator.getCanonicalForm('6 + 4');
      final f2 = validator.getCanonicalForm('(6 + 4)');
      final f3 = validator.getCanonicalForm('((6) + (4))');

      expect(f1, isNotNull);
      expect(f1, equals(f2));
      expect(f1, equals(f3));
    });

    test('canonical form handles commutativity for addition', () {
      final f1 = validator.getCanonicalForm('6 + 4');
      final f2 = validator.getCanonicalForm('4 + 6');
      
      expect(f1, equals(f2));
    });

    test('canonical form handles commutativity for multiplication', () {
      final f1 = validator.getCanonicalForm('10 * 2');
      final f2 = validator.getCanonicalForm('2 * 10');
      
      expect(f1, equals(f2));
    });

    test('canonical form distinguishes different mathematical pathways', () {
      final f1 = validator.getCanonicalForm('6 + 4');
      final f2 = validator.getCanonicalForm('6 + 2 * 2');
      
      expect(f1, isNot(equals(f2)));
    });

    test('canonical form respects precedence', () {
      // (6 + 4) * 2 should not be the same as 6 + 4 * 2
      final f1 = validator.getCanonicalForm('(6 + 4) * 2');
      final f2 = validator.getCanonicalForm('6 + 4 * 2');
      
      expect(f1, isNot(equals(f2)));
    });
  });
}
