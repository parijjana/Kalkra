class SolveResult {
  final int? bestValue;
  final String? expression;
  final bool foundExact;

  SolveResult({this.bestValue, this.expression, this.foundExact = false});
}

class SolverEngine {
  /// Solves the math puzzle with optional operator restrictions and nesting limits.
  SolveResult solve(List<int> pool, int target, {List<String>? allowedOperators, int maxNesting = 10}) {
    if (pool.isEmpty) return SolveResult();

    // Default to all operators if none specified
    final ops = allowedOperators ?? ['+', '-', '*', '/'];

    final solutions = <int, String>{};
    for (final n in pool) {
      solutions[n] = n.toString();
    }

    _search(
      pool.map((e) => e.toDouble()).toList(),
      pool.map((e) => e.toString()).toList(),
      target,
      solutions,
      ops,
      maxNesting,
    );

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

  void _search(
    List<double> numbers,
    List<String> exprs,
    int target,
    Map<int, String> solutions,
    List<String> allowedOps,
    int maxNesting,
  ) {
    if (solutions.containsKey(target)) return;

    for (int i = 0; i < numbers.length; i++) {
      for (int j = 0; j < numbers.length; j++) {
        if (i == j) continue;

        final a = numbers[i];
        final b = numbers[j];
        final sA = exprs[i];
        final sB = exprs[j];

        // Check nesting depth of input operands
        if (_getNestingDepth(sA) >= maxNesting || _getNestingDepth(sB) >= maxNesting) continue;

        final nextNumbers = <double>[];
        final nextExprs = <String>[];
        for (int k = 0; k < numbers.length; k++) {
          if (k != i && k != j) {
            nextNumbers.add(numbers[k]);
            nextExprs.add(exprs[k]);
          }
        }

        // Try allowed operators
        if (allowedOps.contains('+')) {
          _tryOp(a + b, '($sA + $sB)', nextNumbers, nextExprs, target, solutions, allowedOps, maxNesting);
        }

        if (allowedOps.contains('-') && a - b > 0) {
          _tryOp(a - b, '($sA - $sB)', nextNumbers, nextExprs, target, solutions, allowedOps, maxNesting);
        }

        if (allowedOps.contains('*')) {
          _tryOp(a * b, '($sA * $sB)', nextNumbers, nextExprs, target, solutions, allowedOps, maxNesting);
        }

        if (allowedOps.contains('/') && b != 0 && a % b == 0) {
          _tryOp(a / b, '($sA / $sB)', nextNumbers, nextExprs, target, solutions, allowedOps, maxNesting);
        }
      }
    }
  }

  void _tryOp(
    double res,
    String sRes,
    List<double> nextNumbers,
    List<String> nextExprs,
    int target,
    Map<int, String> solutions,
    List<String> allowedOps,
    int maxNesting,
  ) {
    final intRes = res.toInt();
    if (!solutions.containsKey(intRes)) {
      solutions[intRes] = sRes;
    }

    if (nextNumbers.isNotEmpty) {
      final finalNumbers = List<double>.from(nextNumbers)..add(res);
      final finalExprs = List<String>.from(nextExprs)..add(sRes);
      _search(finalNumbers, finalExprs, target, solutions, allowedOps, maxNesting);
    }
  }

  int _getNestingDepth(String expr) {
    int maxDepth = 0;
    int currentDepth = 0;
    for (int i = 0; i < expr.length; i++) {
      if (expr[i] == '(') {
        currentDepth++;
        if (currentDepth > maxDepth) maxDepth = currentDepth;
      } else if (expr[i] == ')') {
        currentDepth--;
      }
    }
    return maxDepth;
  }
}
