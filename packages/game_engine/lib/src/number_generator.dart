import 'dart:math';

enum Difficulty { easy, medium, hard }

class NumberGenerator {
  static const _smallNumbers = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10];
  static const _largeNumbers = [25, 50, 75, 100];

  List<int> generatePool({Difficulty difficulty = Difficulty.medium, int? seed}) {
    final random = Random(seed);
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
    pool.addAll(selectedSmall.take(6 - largeCount));

    return pool..shuffle(random);
  }
}
