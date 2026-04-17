import 'dart:math';
import 'number_generator.dart';

class TargetGenerator {
  int generateTarget({Difficulty difficulty = Difficulty.medium, int? seed}) {
    final random = Random(seed);
    
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
}
