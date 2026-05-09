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
  /// Returns a canonical string representation of an expression to identify duplicates.
  /// Ignores redundant brackets and handles commutativity for + and *.
  String? getCanonicalForm(String expressionString) {
    try {
      final Parser p = Parser();
      final Expression exp = p.parse(expressionString);
      return _toCanonicalString(exp);
    } catch (_) {
      return null;
    }
  }

  String _toCanonicalString(Expression exp) {
    if (exp is Number) {
      return exp.value.toInt().toString();
    }

    if (exp is BinaryOperator) {
      final left = _toCanonicalString(exp.first);
      final right = _toCanonicalString(exp.second);
      
      String op = '';
      bool commutative = false;
      int precedence = 0;

      if (exp is Plus) { op = '+'; commutative = true; precedence = 1; }
      else if (exp is Minus) { op = '-'; precedence = 1; }
      else if (exp is Times) { op = '*'; commutative = true; precedence = 2; }
      else if (exp is Divide) { op = '/'; precedence = 2; }

      final leftStr = _wrapIfLowerPrecedence(exp.first, left, precedence);
      final rightStr = _wrapIfLowerPrecedence(exp.second, right, precedence);

      if (commutative) {
        final sorted = [leftStr, rightStr]..sort();
        return '${sorted[0]} $op ${sorted[1]}';
      }
      return '$leftStr $op $rightStr';
    }

    if (exp is UnaryOperator) {
      if (exp is UnaryMinus) {
        return '-${_wrapIfLowerPrecedence(exp.exp, _toCanonicalString(exp.exp), 3)}';
      }
      return _toCanonicalString(exp.exp);
    }

    return exp.toString();
  }

  String _wrapIfLowerPrecedence(Expression exp, String s, int currentPrecedence) {
    int expPrecedence = 10; // Numbers have highest precedence
    if (exp is Plus || exp is Minus) expPrecedence = 1;
    if (exp is Times || exp is Divide) expPrecedence = 2;
    if (exp is UnaryMinus) expPrecedence = 3;

    if (expPrecedence < currentPrecedence) {
      return '($s)';
    }
    return s;
  }

  ValidationResult validate(String expressionString, List<int> pool, {
    List<RoundConstraint> constraints = const [],
    bool allowNegative = true,
    bool allowFractions = false,
  }) {
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

      // 3. Evaluate and check rules
      final intermediates = <num>[];
      final value = _evaluateAndCheckRules(
        exp, 
        intermediates, 
        allowNegative: allowNegative,
        allowFractions: allowFractions,
      );
      
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

  num _evaluateAndCheckRules(Expression exp, List<num> intermediates, {
    bool allowNegative = true,
    bool allowFractions = false,
  }) {
    if (exp is Number) {
      return exp.value;
    }

    if (exp is BinaryOperator) {
      final left = _evaluateAndCheckRules(exp.first, intermediates, allowNegative: allowNegative, allowFractions: allowFractions);
      final right = _evaluateAndCheckRules(exp.second, intermediates, allowNegative: allowNegative, allowFractions: allowFractions);
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

      if (!allowNegative && result < 0) {
        throw Exception('Intermediate result ($result) must be non-negative');
      }
      if (!allowFractions && result % 1 != 0) {
        throw Exception('Intermediate result ($result) must be an integer');
      }

      intermediates.add(result);
      return result;
    }
    
    if (exp is UnaryOperator) {
      if (exp is UnaryMinus) {
        final val = _evaluateAndCheckRules(exp.exp, intermediates, allowNegative: allowNegative, allowFractions: allowFractions);
        final result = -val;
        if (!allowNegative && result < 0) {
          throw Exception('Intermediate result ($result) must be non-negative');
        }
        intermediates.add(result);
        return result;
      }
      return _evaluateAndCheckRules(exp.exp, intermediates, allowNegative: allowNegative, allowFractions: allowFractions);
    }

    // Default evaluation for anything else
    final val = exp.evaluate(EvaluationType.REAL, ContextModel());
    intermediates.add(val);
    return val;
  }
}
