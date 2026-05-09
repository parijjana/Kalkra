class SolveResult {
  final int? bestValue;
  final String? expression;
  final bool foundExact;

  SolveResult({this.bestValue, this.expression, this.foundExact = false});

  Map<String, dynamic> toJson() => {
    'bestValue': bestValue,
    'expression': expression,
    'foundExact': foundExact,
  };

  factory SolveResult.fromJson(Map<String, dynamic> json) => SolveResult(
    bestValue: json['bestValue'],
    expression: json['expression'],
    foundExact: json['foundExact'] ?? false,
  );
}

class _SolverNode {
  final double value;
  final int precedence;
  final String? expression; // Null until materialized
  final _SolverNode? left;
  final _SolverNode? right;
  final String? op;

  _SolverNode(this.value, this.precedence, {this.expression, this.left, this.right, this.op});

  String get materializedExpression {
    if (expression != null) return expression!;
    
    final sA = left!.materializedExpression;
    final sB = right!.materializedExpression;
    final pA = left!.precedence;
    final pB = right!.precedence;
    final currentPrec = precedence;

    final lStr = pA < currentPrec ? '($sA)' : sA;
    final rStr = pB < currentPrec ? '($sB)' : sB;
    return '$lStr $op $rStr';
  }
}

class SolverEngine {
  /// Finds all reachable integer values from a pool and set of operators.
  Set<int> findAllReachableValues(List<int> pool, {List<String>? allowedOperators, int maxNesting = 10, int? minTarget, int? maxTarget}) {
    if (pool.isEmpty) return {};
    final ops = allowedOperators ?? ['+', '-', '*', '/'];
    final reachable = <int, _SolverNode>{};
    
    _search(
      pool.map((e) => _SolverNode(e.toDouble(), 10, expression: e.toString())).toList(),
      null, 
      reachable,
      ops,
      maxNesting,
    );

    if (minTarget == null && maxTarget == null) return reachable.keys.toSet();

    return reachable.keys
        .where((v) => (minTarget == null || v >= minTarget) && (maxTarget == null || v <= maxTarget))
        .toSet();
  }

  /// Solves the math puzzle with optional operator restrictions and nesting limits.
  SolveResult solve(List<int> pool, int target, {List<String>? allowedOperators, int maxNesting = 10}) {
    if (pool.isEmpty) return SolveResult();

    final ops = allowedOperators ?? ['+', '-', '*', '/'];
    final solutions = <int, _SolverNode>{};
    
    final initialNodes = pool.map((e) => _SolverNode(e.toDouble(), 10, expression: e.toString())).toList();
    for (final node in initialNodes) {
      solutions[node.value.toInt()] = node;
    }

    _search(initialNodes, target, solutions, ops, maxNesting);

    if (solutions.containsKey(target)) {
      return SolveResult(bestValue: target, expression: solutions[target]!.materializedExpression, foundExact: true);
    }

    // Find closest if exact not found
    int? closest;
    int minDiff = 1000000;
    for (final val in solutions.keys) {
      final diff = (val - target).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = val;
      }
    }

    return SolveResult(bestValue: closest, expression: solutions[closest]?.materializedExpression);
  }

  void _search(
    List<_SolverNode> nodes,
    int? target,
    Map<int, _SolverNode> solutions,
    List<String> allowedOps,
    int maxNesting,
  ) {
    if (target != null && solutions.containsKey(target)) return;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = 0; j < nodes.length; j++) {
        if (i == j) continue;

        final a = nodes[i];
        final b = nodes[j];

        final nextNodesBase = <_SolverNode>[];
        for (int k = 0; k < nodes.length; k++) {
          if (k != i && k != j) nextNodesBase.add(nodes[k]);
        }

        // Try allowed operators
        if (allowedOps.contains('+')) {
          _tryOp(_SolverNode(a.value + b.value, 1, left: a, right: b, op: '+'), nextNodesBase, target, solutions, allowedOps, maxNesting);
        }

        if (allowedOps.contains('-') && a.value - b.value > 0) {
          _tryOp(_SolverNode(a.value - b.value, 1, left: a, right: b, op: '-'), nextNodesBase, target, solutions, allowedOps, maxNesting);
        }

        if (allowedOps.contains('*') && a.value != 1 && b.value != 1) {
          _tryOp(_SolverNode(a.value * b.value, 2, left: a, right: b, op: '*'), nextNodesBase, target, solutions, allowedOps, maxNesting);
        }

        if (allowedOps.contains('/') && b.value != 0 && b.value != 1 && a.value % b.value == 0) {
          _tryOp(_SolverNode(a.value / b.value, 2, left: a, right: b, op: '/'), nextNodesBase, target, solutions, allowedOps, maxNesting);
        }
        
        if (target != null && solutions.containsKey(target)) return;
      }
    }
  }

  void _tryOp(
    _SolverNode res,
    List<_SolverNode> nextNodesBase,
    int? target,
    Map<int, _SolverNode> solutions,
    List<String> allowedOps,
    int maxNesting,
  ) {
    final intRes = res.value.toInt();
    if (!solutions.containsKey(intRes)) {
      solutions[intRes] = res;
    }

    if (target != null && intRes == target) return;

    if (nextNodesBase.isNotEmpty) {
      final nextNodes = List<_SolverNode>.from(nextNodesBase)..add(res);
      _search(nextNodes, target, solutions, allowedOps, maxNesting);
    }
  }
}
