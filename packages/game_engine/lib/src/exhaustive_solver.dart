import 'dart:math';

/// A node in the exhaustive search tree.
class _ExhaustiveNode {
  final int value;
  final String expression;
  final int precedence; // 3: atomic, 2: */, 1: +-

  const _ExhaustiveNode(this.value, this.expression, this.precedence);
}

/// An exhaustive solver to find all possible results from a set of numbers.
class ExhaustiveSolver {
  /// Finds all unique integer results reachable from the given pool.
  Set<int> findAllReachableValues(List<int> pool, {List<String>? allowedOps}) {
    if (pool.isEmpty) return {};
    final ops = allowedOps ?? ['+', '-', '*', '/'];
    
    // Maps a bitmask of used numbers to the map of (value -> best node).
    final Map<int, Map<int, _ExhaustiveNode>> memo = {};

    // Base cases: single numbers
    for (int i = 0; i < pool.length; i++) {
      memo[1 << i] = {pool[i]: _ExhaustiveNode(pool[i], pool[i].toString(), 3)};
    }

    // Iterate through all possible subset sizes
    for (int size = 2; size <= pool.length; size++) {
      for (int mask = 1; mask < (1 << pool.length); mask++) {
        if (_countSetBits(mask) != size) continue;

        final results = <int, _ExhaustiveNode>{};
        // Split mask into two non-empty sub-masks
        for (int submask = 1; submask < mask; submask++) {
          if ((submask & mask) == submask) {
            final otherMask = mask ^ submask;
            if (submask > otherMask) continue; // Avoid redundant pairs

            final map1 = memo[submask] ?? {};
            final map2 = memo[otherMask] ?? {};

            for (final n1 in map1.values) {
              for (final n2 in map2.values) {
                _combine(n1, n2, ops, results);
              }
            }
          }
        }
        memo[mask] = results;
      }
    }

    final allReachable = <int>{};
    for (final subsetResults in memo.values) {
      allReachable.addAll(subsetResults.keys);
    }

    return allReachable;
  }

  int _countSetBits(int n) {
    int count = 0;
    while (n > 0) {
      n &= (n - 1);
      count++;
    }
    return count;
  }

  void _combine(_ExhaustiveNode n1, _ExhaustiveNode n2, List<String> ops, Map<int, _ExhaustiveNode> results) {
    // Try both directions for non-commutative operations
    final pairs = [[n1, n2], [n2, n1]];
    
    for (final p in pairs) {
      final a = p[0];
      final b = p[1];

      if (ops.contains('+')) {
        _addResult(a.value + b.value, _formatExpr(a, '+', b), 1, results);
      }
      if (ops.contains('-') && a.value - b.value > 0) {
        _addResult(a.value - b.value, _formatExpr(a, '-', b), 1, results);
      }
      if (ops.contains('*') && a.value != 1 && b.value != 1) {
        _addResult(a.value * b.value, _formatExpr(a, '*', b), 2, results);
      }
      if (ops.contains('/') && b.value != 0 && b.value != 1 && a.value % b.value == 0) {
        _addResult(a.value ~/ b.value, _formatExpr(a, '/', b), 2, results);
      }
    }
  }

  String _formatExpr(_ExhaustiveNode left, String op, _ExhaustiveNode right) {
    final int opPrec = (op == '*' || op == '/') ? 2 : 1;
    
    String lStr = left.expression;
    if (left.precedence < opPrec) {
      lStr = '($lStr)';
    }

    String rStr = right.expression;
    // Right side wrapping rules:
    // 1. If right precedence is lower than op precedence, ALWAYS wrap.
    // 2. If right precedence is equal, wrap for non-associative/non-commutative cases:
    //    A - (B + C) needs wrap. A - (B - C) needs wrap.
    //    A / (B * C) needs wrap. A / (B / C) needs wrap.
    bool wrapRight = right.precedence < opPrec;
    if (!wrapRight && right.precedence == opPrec) {
      if (op == '-' || op == '/') wrapRight = true;
    }

    if (wrapRight) {
      rStr = '($rStr)';
    }

    return '$lStr$op$rStr';
  }

  void _addResult(int val, String expr, int prec, Map<int, _ExhaustiveNode> results) {
    if (!results.containsKey(val) || expr.length < results[val]!.expression.length) {
      results[val] = _ExhaustiveNode(val, expr, prec);
    }
  }
}
