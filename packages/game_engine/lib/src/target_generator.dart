import 'dart:math';
import 'number_generator.dart';
import 'round_config.dart';

class TargetGenerator {
  int generateTarget({Difficulty difficulty = Difficulty.medium, int? seed, TargetType type = TargetType.standard}) {
    final random = Random(seed);
    
    if (type == TargetType.countdown) {
      // Starts high
      return 800 + random.nextInt(200);
    }

    switch (difficulty) {
      case Difficulty.easy:
        // Range 50 to 250 (Easier with 1 large number)
        return 50 + random.nextInt(201);
      case Difficulty.medium:
        // Range 100 to 999 (Standard)
        return 100 + random.nextInt(900);
      case Difficulty.hard:
        // Range 400 to 999 (Requires more complex combinations)
        return 400 + random.nextInt(600);
    }
  }

  List<int> generateTargets({int count = 1, Difficulty difficulty = Difficulty.medium, int? seed}) {
    final random = Random(seed);
    final targets = <int>{};
    while (targets.length < count) {
      targets.add(generateTarget(difficulty: difficulty, seed: random.nextInt(1000000)));
    }
    return targets.toList()..sort();
  }
}
