import 'dart:math';

class TargetGenerator {
  int generateTarget({int? seed}) {
    final random = Random(seed);
    // Range 100 to 999 inclusive
    return 100 + random.nextInt(900);
  }
}
