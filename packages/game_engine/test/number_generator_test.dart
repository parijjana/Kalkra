import 'package:test/test.dart';
import 'package:game_engine/src/number_generator.dart';

void main() {
  group('NumberGenerator', () {
    late NumberGenerator generator;

    setUp(() {
      generator = NumberGenerator();
    });

    test('generates exactly 6 numbers by default', () {
      final numbers = generator.generatePool();
      expect(numbers.length, 6);
    });

    test('generated numbers are within valid range (1-100)', () {
      final numbers = generator.generatePool();
      for (final n in numbers) {
        expect(n, greaterThanOrEqualTo(1));
        expect(n, lessThanOrEqualTo(100));
      }
    });

    test('generates different numbers for different seeds', () {
      final numbers1 = generator.generatePool(seed: 123);
      final numbers2 = generator.generatePool(seed: 456);
      expect(numbers1, isNot(equals(numbers2)));
    });

    test('generates same numbers for same seed', () {
      final numbers1 = generator.generatePool(seed: 789);
      final numbers2 = generator.generatePool(seed: 789);
      expect(numbers1, equals(numbers2));
    });

    test('easy preset contains more small numbers', () {
      final pool = generator.generatePool(difficulty: Difficulty.easy, seed: 1);
      // Small numbers typically 1-10. Let's assume easy has at most 1 large number.
      // Large numbers are usually 25, 50, 75, 100.
      final largeNumbers = pool.where((n) => n > 10).toList();
      expect(largeNumbers.length, lessThanOrEqualTo(2));
    });

    test('hard preset contains more large numbers', () {
      final pool = generator.generatePool(difficulty: Difficulty.hard, seed: 1);
      final largeNumbers = pool.where((n) => n > 10).toList();
      expect(largeNumbers.length, greaterThanOrEqualTo(2));
    });
  });
}
