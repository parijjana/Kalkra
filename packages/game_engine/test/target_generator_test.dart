import 'package:test/test.dart';
import 'package:game_engine/src/target_generator.dart';

void main() {
  group('TargetGenerator', () {
    late TargetGenerator generator;

    setUp(() {
      generator = TargetGenerator();
    });

    test('generates a target between 100 and 999', () {
      final target = generator.generateTarget();
      expect(target, greaterThanOrEqualTo(100));
      expect(target, lessThanOrEqualTo(999));
    });

    test('generates same target for same seed', () {
      final target1 = generator.generateTarget(seed: 101);
      final target2 = generator.generateTarget(seed: 101);
      expect(target1, equals(target2));
    });

    test('generates different targets for different seeds', () {
      final target1 = generator.generateTarget(seed: 202);
      final target2 = generator.generateTarget(seed: 303);
      expect(target1, isNot(equals(target2)));
    });
  });
}
