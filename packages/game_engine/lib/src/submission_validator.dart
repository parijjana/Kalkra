import 'package:math_expressions/math_expressions.dart';
import 'round_config.dart';

class ValidationResult {
  final bool isValid;
  final num? value;
  final String? error;
  final List<int> usedNumbers;
  final List<String> operators;
  final List<num> intermediateResults;

  ValidationResult.success(this.value, {
    this.usedNumbers = const [],
    this.operators = const [],
    this.intermediateResults = const [],
  }) : isValid = true, error = null;

  ValidationResult.failure(this.error)
      : isValid = false,
        value = null,
        usedNumbers = const [],
        operators = const [],
        intermediateResults = const [];
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
      final intermediates = <num>[];
      final value = _evaluateAndCheckRules(exp, intermediates);
      
      return ValidationResult.success(
        value,
        usedNumbers: usedNumbers,
        operators: operations,
        intermediateResults: intermediates,
      );
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

  num _evaluateAndCheckRules(Expression exp, List<num> intermediates) {
    if (exp is Number) {
      return exp.value;
    }

    if (exp is BinaryOperator) {
      final left = _evaluateAndCheckRules(exp.first, intermediates);
      final right = _evaluateAndCheckRules(exp.second, intermediates);
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

      final finalRes = result.toInt();
      intermediates.add(finalRes);
      return finalRes;
    }
    
    if (exp is UnaryOperator) {
      if (exp is UnaryMinus) {
        final val = _evaluateAndCheckRules(exp.exp, intermediates);
        final result = -val;
        if (result <= 0) {
          throw Exception('Intermediate result ($result) must be positive');
        }
        intermediates.add(result);
        return result;
      }
      return _evaluateAndCheckRules(exp.exp, intermediates);
    }

    // Default evaluation for anything else
    final val = exp.evaluate(EvaluationType.REAL, ContextModel());
    intermediates.add(val);
    return val;
  }
}
