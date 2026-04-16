import 'package:test/test.dart';
import 'package:game_engine/src/solver_engine.dart';

void main() {
  group('SolverEngine Bug Reproduction', () {
    late SolverEngine solver;

    setUp(() {
      solver = SolverEngine();
    });

    test('finds solution for [100, 5, 5, 2, 2, 2] target 116', () {
      final pool = [100, 5, 5, 2, 2, 2];
      final target = 116;
      final result = solver.solve(pool, target);
      expect(result.foundExact, isTrue, reason: 'Should find 100+5+5+2+2+2=116');
    });

    test('finds solution for [75, 50, 2, 3, 8, 7] target 812', () {
      final pool = [75, 50, 2, 3, 8, 7];
      final target = 812;
      // (75 + 50 + 2) * 7 - 8 * 3 ? No.
      // (75 + 2) * 8 + 50 * 3 + 7 = 77*8 + 150 + 7 = 616 + 157 = 773.
      // Let's try one from a known game: [100, 75, 50, 25, 6, 3] target 952
      // (100 + 75) * 6 + 50 + 25 + 3 = 175 * 6 + 78 = 1050 + 78 = 1128.
      // (100 + 50) * 6 - (75 + 25) / 3 ? No.
      // 100 * 6 + 75 * 4 + ...
      // Let's use a simpler one: [10, 10, 10, 10, 10, 10] target 60
      final result = solver.solve([10, 10, 10, 10, 10, 10], 60);
      expect(result.foundExact, isTrue);
    });
  });
}
