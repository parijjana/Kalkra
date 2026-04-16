class SolveResult {
  final int? bestValue;
  final String? expression;
  final bool foundExact;

  SolveResult({this.bestValue, this.expression, this.foundExact = false});
}

class SolverEngine {
  SolveResult solve(List<int> pool, int target) {
    if (pool.isEmpty) return SolveResult();

    final solutions = <int, String>{};
    for (final n in pool) {
      solutions[n] = n.toString();
    }

    _search(pool.map((e) => e.toDouble()).toList(), 
            pool.map((e) => e.toString()).toList(), 
            target, 
            solutions);

    if (solutions.containsKey(target)) {
      return SolveResult(bestValue: target, expression: solutions[target], foundExact: true);
    }

    // Find closest
    int? closest;
    int minDiff = 1000000;
    for (final val in solutions.keys) {
      final diff = (val - target).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = val;
      }
    }

    return SolveResult(bestValue: closest, expression: solutions[closest]);
  }

  void _search(List<double> numbers, List<String> exprs, int target, Map<int, String> solutions) {
    if (solutions.containsKey(target)) return;

    for (int i = 0; i < numbers.length; i++) {
      for (int j = 0; j < numbers.length; j++) {
        if (i == j) continue;

        final a = numbers[i];
        final b = numbers[j];
        final sA = exprs[i];
        final sB = exprs[j];

        final nextNumbers = <double>[];
        final nextExprs = <String>[];
        for (int k = 0; k < numbers.length; k++) {
          if (k != i && k != j) {
            nextNumbers.add(numbers[k]);
            nextExprs.add(exprs[k]);
          }
        }

        // Try all operators
        _tryOp(a + b, '($sA + $sB)', nextNumbers, nextExprs, target, solutions);
        
        if (a - b > 0) {
          _tryOp(a - b, '($sA - $sB)', nextNumbers, nextExprs, target, solutions);
        }
        
        _tryOp(a * b, '($sA * $sB)', nextNumbers, nextExprs, target, solutions);
        
        if (b != 0 && a % b == 0) {
          _tryOp(a / b, '($sA / $sB)', nextNumbers, nextExprs, target, solutions);
        }
      }
    }
  }

  void _tryOp(double res, String sRes, List<double> nextNumbers, List<String> nextExprs, int target, Map<int, String> solutions) {
    final iRes = res.toInt();
    if (!solutions.containsKey(iRes)) {
      solutions[iRes] = sRes;
    }
    
    if (iRes == target) return;
    if (nextNumbers.isEmpty) return;

    final newNumbers = List<double>.from(nextNumbers)..add(res);
    final newExprs = List<String>.from(nextExprs)..add(sRes);
    _search(newNumbers, newExprs, target, solutions);
  }
}
