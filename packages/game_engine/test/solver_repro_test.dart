import 'package:test/test.dart';
import 'package:game_engine/src/solver_engine.dart';

void main() {
  group('SolverEngine Bug Reproduction', () {
    late SolverEngine solver;

    setUp(() {
      solver = SolverEngine();
    });

    test('finds solution for [100, 5, 5, 2, 2, 2] target 116', () {
      final result = solver.solve([100, 5, 5, 2, 2, 2], 116);
      expect(result.foundExact, isTrue, reason: 'Should find 100+5+5+2+2+2=116');
    });

    test('finds solution for simple [10, 10, 10, 10, 10, 10] target 60', () {
      final result = solver.solve([10, 10, 10, 10, 10, 10], 60);
      expect(result.foundExact, isTrue);
    });
  });
}
