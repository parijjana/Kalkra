import 'package:math_expressions/math_expressions.dart';
import 'round_config.dart';

class ValidationResult {
  final bool isValid;
  final num? value;
  final String? error;

  ValidationResult.success(this.value) : isValid = true, error = null;
  ValidationResult.failure(this.error) : isValid = false, value = null;
}

class SubmissionValidator {
  ValidationResult validate(String expressionString, List<int> pool, {List<RoundConstraint> constraints = const []}) {
    try {
      final Parser p = Parser();
      final Expression exp = p.parse(expressionString);

      // 1. Check if used numbers are in the pool
      final usedNumbers = _extractNumbers(exp);
      final poolCopy = List<int>.from(pool);

      for (final n in usedNumbers) {
        if (!poolCopy.remove(n)) {
          return ValidationResult.failure('$n is not available or used too many times');
        }
      }

      // 2. Check dynamic constraints (e.g. Forbidden Number)
      final operations = _extractOperators(exp);
      for (final constraint in constraints) {
        if (!constraint.validate(usedNumbers, operations)) {
          return ValidationResult.failure(constraint.description);
        }
      }

      // 3. Evaluate and check rules (positive integers)
      final value = _evaluateAndCheckRules(exp);
      return ValidationResult.success(value);
    } catch (e) {
      return ValidationResult.failure(e.toString());
    }
  }

  List<String> _extractOperators(Expression exp) {
    final ops = <String>[];
    if (exp is BinaryOperator) {
      ops.add(exp.toString());
      ops.addAll(_extractOperators(exp.first));
      ops.addAll(_extractOperators(exp.second));
    } else if (exp is UnaryOperator) {
      ops.add(exp.toString());
      ops.addAll(_extractOperators(exp.exp));
    }
    return ops;
  }

  List<int> _extractNumbers(Expression exp) {
    final numbers = <int>[];
    if (exp is Number) {
      numbers.add(exp.value.toInt());
    } else if (exp is BinaryOperator) {
      numbers.addAll(_extractNumbers(exp.first));
      numbers.addAll(_extractNumbers(exp.second));
    } else if (exp is UnaryOperator) {
      numbers.addAll(_extractNumbers(exp.exp));
    }
    return numbers;
  }

  num _evaluateAndCheckRules(Expression exp) {
    if (exp is Number) {
      return exp.value;
    }

    if (exp is BinaryOperator) {
      final left = _evaluateAndCheckRules(exp.first);
      final right = _evaluateAndCheckRules(exp.second);
      num result;

      if (exp is Plus) {
        result = left + right;
      } else if (exp is Minus) {
        result = left - right;
      } else if (exp is Times) {
        result = left * right;
      } else if (exp is Divide) {
        if (right == 0) throw Exception('Division by zero');
        result = left / right;
      } else {
        throw Exception('Unsupported operator');
      }

      if (result <= 0) {
        throw Exception('Intermediate result ($result) must be positive');
      }
      if (result % 1 != 0) {
        throw Exception('Intermediate result ($result) must be an integer');
      }

      return result.toInt();
    }
    
    if (exp is UnaryOperator) {
      if (exp is UnaryMinus) {
        final val = _evaluateAndCheckRules(exp.exp);
        final result = -val;
        if (result <= 0) {
          throw Exception('Intermediate result ($result) must be positive');
        }
        return result;
      }
      return _evaluateAndCheckRules(exp.exp);
    }

    // Default evaluation for anything else
    return exp.evaluate(EvaluationType.REAL, ContextModel());
  }
}
