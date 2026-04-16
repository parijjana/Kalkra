import 'package:test/test.dart';
import 'package:game_engine/src/submission_validator.dart';
import 'package:game_engine/src/round_config.dart';

void main() {
  group('SubmissionValidator', () {
    late SubmissionValidator validator;
    final pool = [1, 2, 3, 4, 5, 10];

    setUp(() {
      validator = SubmissionValidator();
    });

    test('validates a correct expression using allowed numbers', () {
      final result = validator.validate('1 + 2 + 3', pool);
      expect(result.isValid, isTrue);
      expect(result.value, equals(6));
    });

    test('fails if expression uses numbers not in the pool', () {
      final result = validator.validate('1 + 20', pool);
      expect(result.isValid, isFalse);
      expect(result.error, contains('20 is not available'));
    });

    test('fails if expression uses the same number too many times', () {
      final result = validator.validate('1 + 1', pool);
      expect(result.isValid, isFalse);
      expect(result.error, contains('used too many times'));
    });

    test('handles basic operators (+, -, *, /)', () {
      expect(validator.validate('10 * 2', pool).value, 20);
      expect(validator.validate('10 - 5', pool).value, 5);
      expect(validator.validate('10 / 2', pool).value, 5);
    });

    test('fails if intermediate result is not a positive integer (division)', () {
      final result = validator.validate('3 / 2', pool);
      expect(result.isValid, isFalse);
      expect(result.error, contains('integer'));
    });

    test('fails if intermediate result is negative', () {
      final result = validator.validate('1 - 5', pool);
      expect(result.isValid, isFalse);
      expect(result.error, contains('positive'));
    });

    test('handles parentheses correctly', () {
      final result = validator.validate('(1 + 2) * 3', pool);
      expect(result.isValid, isTrue);
      expect(result.value, equals(9));
    });

    test('fails on syntax errors', () {
      final result = validator.validate('1 + * 2', pool);
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });
  });
}
