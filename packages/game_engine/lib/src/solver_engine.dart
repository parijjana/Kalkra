import 'dart:math';

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
  final int precedence; // 3: atomic, 2: */, 1: +-
  final _SolverNode? left;
  final _SolverNode? right;
  final String? op;
  final String? expression;

  _SolverNode(this.value, this.precedence, {this.left, this.right, this.op, this.expression});

  String get materializedExpression {
    if (expression != null) return expression!;
    if (left != null && right != null && op != null) {
      final int opPrec = (op == '*' || op == '/') ? 2 : 1;
      
      String lStr = left!.materializedExpression;
      if (left!.precedence < opPrec) {
        lStr = '($lStr)';
      }

      String rStr = right!.materializedExpression;
      bool wrapRight = right!.precedence < opPrec;
      if (!wrapRight && right!.precedence == opPrec) {
        if (op == '-' || op == '/') wrapRight = true;
      }
      if (wrapRight) {
        rStr = '($rStr)';
      }

      return '$lStr$op$rStr';
    }
    return value.toInt().toString();
  }
}

class SolverEngine {
  /// Solves the math puzzle with optional operator restrictions and nesting limits.
  SolveResult solve(List<int> pool, int target, {List<String>? allowedOperators, int maxNesting = 10}) {
    if (pool.isEmpty) return SolveResult();

    final ops = allowedOperators ?? ['+', '-', '*', '/'];
    final solutions = <int, _SolverNode>{};
    
    final initialNodes = pool.map((e) => _SolverNode(e.toDouble(), 3, expression: e.toString())).toList();
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
    if (!solutions.containsKey(intRes) || res.materializedExpression.length < solutions[intRes]!.materializedExpression.length) {
      solutions[intRes] = res;
    }

    if (target != null && intRes == target) return;

    if (nextNodesBase.isNotEmpty) {
      final nextNodes = List<_SolverNode>.from(nextNodesBase)..add(res);
      _search(nextNodes, target, solutions, allowedOps, maxNesting);
    }
  }
}
