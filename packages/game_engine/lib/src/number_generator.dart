import 'dart:math';
import 'round_config.dart';

enum Difficulty { easy, medium, hard }

class NumberGenerator {
  static const _smallNumbers = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10];
  static const _largeNumbers = [25, 50, 75, 100];
  static const _primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47];
  static const _powersOf2 = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024];
  static const _powersOf3 = [3, 9, 27, 81, 243, 729, 2187];

  List<int> generatePool({
    Difficulty difficulty = Difficulty.medium, 
    int? seed,
    PoolType poolType = PoolType.standard,
  }) {
    final random = Random(seed);
    
    if (poolType == PoolType.powersOf2) {
      final selected = List<int>.from(_powersOf2)..shuffle(random);
      return selected.take(6).toList()..shuffle(random);
    }

    if (poolType == PoolType.powersOf3) {
      final selected = List<int>.from(_powersOf3)..shuffle(random);
      return selected.take(6).toList()..shuffle(random);
    }

    if (poolType == PoolType.smallOnly) {
      final selectedSmall = List<int>.from(_smallNumbers)..shuffle(random);
      return selectedSmall.take(6).toList()..shuffle(random);
    }

    if (poolType == PoolType.primesOnly) {
      final selectedPrimes = List<int>.from(_primes)..shuffle(random);
      return selectedPrimes.take(6).toList()..shuffle(random);
    }

    if (poolType == PoolType.expanding) {
      // Standard hard-style pool to ensure it's solvable eventually
      final selectedLarge = List<int>.from(_largeNumbers)..shuffle(random);
      final pool = <int>[...selectedLarge.take(2)];
      final selectedSmall = List<int>.from(_smallNumbers)..shuffle(random);
      pool.addAll(selectedSmall.take(4));
      return pool..shuffle(random);
    }

    final pool = <int>[];

    int largeCount;
    switch (difficulty) {
      case Difficulty.easy:
        largeCount = 1;
        break;
      case Difficulty.medium:
        largeCount = 2;
        break;
      case Difficulty.hard:
        largeCount = 3;
        break;
    }

    final selectedLarge = List<int>.from(_largeNumbers)..shuffle(random);
    pool.addAll(selectedLarge.take(largeCount));

    final selectedSmall = List<int>.from(_smallNumbers)..shuffle(random);
    int remainingCount = (difficulty == Difficulty.easy) ? 3 : (6 - largeCount);
    pool.addAll(selectedSmall.take(remainingCount));

    return pool..shuffle(random);
  }
}
