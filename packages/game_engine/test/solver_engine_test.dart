import 'package:test/test.dart';
import 'package:game_engine/src/solver_engine.dart';

void main() {
  group('SolverEngine', () {
    late SolverEngine solver;

    setUp(() {
      solver = SolverEngine();
    });

    test('finds an exact solution if it exists', () {
      final pool = [1, 2, 3, 4, 5, 10];
      final target = 100;
      // Possible exact: (1+2+3+4)*10 = 100
      final result = solver.solve(pool, target);
      expect(result.foundExact, isTrue);
      expect(result.bestValue, equals(target));
      expect(result.expression, isNotNull);
    });

    test('finds the closest solution if exact does not exist', () {
      final pool = [2, 4, 6, 8, 10, 25];
      final target = 999;
      // Let's assume there's no exact. It should find something close.
      final result = solver.solve(pool, target);
      expect(result.bestValue, isNotNull);
      expect(result.expression, isNotNull);
    });

    test('handles empty pool gracefully', () {
      final result = solver.solve([], 100);
      expect(result.foundExact, isFalse);
      expect(result.bestValue, isNull);
    });
  });
}
