import 'dart:math';
import 'number_generator.dart';
import 'round_config.dart';
import 'exhaustive_solver.dart';
import 'solver_engine.dart';

class TargetGenerator {
  final ExhaustiveSolver _exhaustiveSolver = ExhaustiveSolver();
  final SolverEngine _solver = SolverEngine();

  int generateTarget({
    Difficulty difficulty = Difficulty.medium,
    int? seed,
    TargetType type = TargetType.standard,
    List<int> excludedTargets = const [],
  }) {
    final random = Random(seed);
    
    if (type == TargetType.powersOf2) {
      final powers = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024];
      final available = powers.where((p) => !excludedTargets.contains(p)).toList();
      return available[random.nextInt(available.length)];
    }

    int minT = 100;
    int maxT = 999;
    
    if (difficulty == Difficulty.easy) {
      minT = 10; maxT = 150;
    } else if (difficulty == Difficulty.medium) {
      minT = 100; maxT = 500;
    }

    return minT + random.nextInt(maxT - minT);
  }

  /// Generates a set of reachable targets for standard game modes.
  List<int> generateReachableTargets({
    int count = 1,
    required List<int> pool,
    List<String>? allowedOperators,
    Difficulty difficulty = Difficulty.medium,
    int? seed,
    TargetType type = TargetType.standard,
    Set<int> excludedTargets = const {},
  }) {
    final random = Random(seed);
    final targets = <int>{};
    int attempts = 0;

    while (targets.length < count && attempts < 50) {
      final t = generateTarget(
        difficulty: difficulty,
        seed: random.nextInt(1000000),
        type: type,
        excludedTargets: excludedTargets.toList(),
      );

      final res = _solver.solve(pool, t, allowedOperators: allowedOperators);
      if (res.foundExact && !targets.contains(t) && !excludedTargets.contains(t)) {
        targets.add(t);
      }
      attempts++;
    }

    // Fallback: if we can't find exact solutions, find any reachable values
    if (targets.length < count) {
      final reachable = _exhaustiveSolver.findAllReachableValues(pool, allowedOps: allowedOperators);
      final available = reachable.where((v) => v >= 10 && v <= 999 && !targets.contains(v) && !excludedTargets.contains(v)).toList();
      available.shuffle(random);
      for (final v in available.take(count - targets.length)) {
        targets.add(v);
      }
    }

    return targets.toList()..sort();
  }

  /// Generates a set of 9 targets for the Triple Threat mode: 3 reachable, 6 unreachable.
  List<int> generateTripleThreatTargets({
    required List<int> pool,
    List<String>? allowedOperators,
    Difficulty difficulty = Difficulty.medium,
    int? seed,
  }) {
    final random = Random(seed);
    final reachable = _exhaustiveSolver.findAllReachableValues(
      pool,
      allowedOps: allowedOperators,
    );

    final filteredReachable = reachable.where((v) => v >= 10 && v <= 999).toList();

    if (filteredReachable.length < 3) {
      // Fallback: if pool is very weak, generate standard targets
      final List<int> fallback = [];
      for (int i = 0; i < 9; i++) {
        fallback.add(generateTarget(difficulty: difficulty, seed: random.nextInt(1000000)));
      }
      return fallback;
    }

    filteredReachable.shuffle(random);
    final selectedReachable = filteredReachable.take(3).toList()..sort((a, b) => b.compareTo(a));

    final unreachable = <int>{};
    int attempts = 0;
    while (unreachable.length < 6 && attempts < 500) {
      final candidate = 10 + random.nextInt(989);
      if (!reachable.contains(candidate) && !selectedReachable.contains(candidate)) {
        unreachable.add(candidate);
      }
      attempts++;
    }

    // Fill with randoms if still short (extremely unlikely with 500 attempts, but for absolute safety)
    while (unreachable.length < 6) {
      final candidate = 1000 + random.nextInt(1000); // Outside normal range to avoid collision
      unreachable.add(candidate);
    }

    // Combined list: [R1, R2, R3, U1, U2, U3, U4, U5, U6]
    return [...selectedReachable, ...unreachable];
  }

  /// Generates a set of 4 targets for the Double Danger mode: 2 reachable, 2 unreachable.
  List<int> generateDoubleDangerTargets({
    required List<int> pool,
    List<String>? allowedOperators,
    Difficulty difficulty = Difficulty.medium,
    int? seed,
  }) {
    final random = Random(seed);
    final reachable = _exhaustiveSolver.findAllReachableValues(
      pool,
      allowedOps: allowedOperators,
    );

    final filteredReachable = reachable.where((v) => v >= 10 && v <= 999).toList();

    if (filteredReachable.length < 2) {
      final List<int> fallback = [];
      for (int i = 0; i < 4; i++) {
        fallback.add(generateTarget(difficulty: difficulty, seed: random.nextInt(1000000)));
      }
      return fallback;
    }

    filteredReachable.shuffle(random);
    final selectedReachable = filteredReachable.take(2).toList()..sort((a, b) => b.compareTo(a));

    final unreachable = <int>{};
    int attempts = 0;
    while (unreachable.length < 2 && attempts < 200) {
      final candidate = 10 + random.nextInt(989);
      if (!reachable.contains(candidate) && !selectedReachable.contains(candidate)) {
        unreachable.add(candidate);
      }
      attempts++;
    }

    while (unreachable.length < 2) {
      unreachable.add(1000 + random.nextInt(1000));
    }

    return [...selectedReachable, ...unreachable];
  }

  List<int> generateTargets({int count = 1, Difficulty difficulty = Difficulty.medium, int? seed, TargetType type = TargetType.standard}) {
    final random = Random(seed);
    final targets = <int>{};
    final localExclusions = <int>[];
    int attempts = 0;
    
    while (targets.length < count && attempts < 20) {
      final t = generateTarget(
        difficulty: difficulty,
        seed: random.nextInt(1000000),
        type: type,
        excludedTargets: localExclusions,
      );
      targets.add(t);
      localExclusions.add(t);
      attempts++;
    }
    
    return targets.toList()..sort();
  }
}
