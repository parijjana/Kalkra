import 'dart:math';
import 'number_generator.dart';
import 'round_config.dart';
import 'solver_engine.dart';

class TargetGenerator {
  final SolverEngine _solver = SolverEngine();

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

  /// Generates a target that is guaranteed to be reachable with the given pool and operators.
  int generateReachableTarget({
    required List<int> pool,
    List<String>? allowedOperators,
    Difficulty difficulty = Difficulty.medium,
    int? seed,
    TargetType type = TargetType.standard,
    Set<int>? excludedTargets,
  }) {
    final random = Random(seed);
    
    int minT = 100;
    int maxT = 999;
    
    if (type == TargetType.countdown) {
      minT = 800; maxT = 999;
    } else {
      switch (difficulty) {
        case Difficulty.easy: minT = 50; maxT = 250; break;
        case Difficulty.medium: minT = 100; maxT = 999; break;
        case Difficulty.hard: minT = 400; maxT = 999; break;
      }
    }

    // Optimization: Constructive approach
    // Pick N random targets and check if they are solvable.
    
    int? bestCandidate;
    int minDistance = 1000000;

    for (int i = 0; i < 20; i++) {
      final candidate = minT + random.nextInt(maxT - minT + 1);
      if (excludedTargets != null && excludedTargets.contains(candidate)) continue;

      final res = _solver.solve(pool, candidate, allowedOperators: allowedOperators);
      if (res.foundExact) return candidate;

      final resultVal = res.bestValue ?? pool.first;
      final dist = (resultVal - candidate).abs();
      
      // Keep track of the closest reachable value that isn't excluded
      if (excludedTargets == null || !excludedTargets.contains(resultVal)) {
        if (dist < minDistance) {
          minDistance = dist;
          bestCandidate = resultVal;
        }
      }
    }

    // If we found a non-excluded reachable candidate, use it.
    if (bestCandidate != null) return bestCandidate;

    // Last resort fallback: find ANY value in the pool not excluded
    for (final p in pool) {
      if (excludedTargets == null || !excludedTargets.contains(p)) return p;
    }

    // Absolute fallback: random number (may duplicate if set is exhausted)
    return pool[random.nextInt(pool.length)];
  }

  List<int> generateTargets({int count = 1, Difficulty difficulty = Difficulty.medium, int? seed}) {
    final random = Random(seed);
    final targets = <int>{};
    while (targets.length < count) {
      targets.add(generateTarget(difficulty: difficulty, seed: random.nextInt(1000000)));
    }
    return targets.toList()..sort();
  }

  List<int> generateReachableTargets({
    int count = 1,
    required List<int> pool,
    List<String>? allowedOperators,
    Difficulty difficulty = Difficulty.medium,
    int? seed,
    TargetType type = TargetType.standard,
    Set<int>? excludedTargets,
  }) {
    final random = Random(seed);
    final targets = <int>{};
    final localExclusions = Set<int>.from(excludedTargets ?? {});
    
    int attempts = 0;
    while (targets.length < count && attempts < 30) {
      final t = generateReachableTarget(
        pool: pool,
        allowedOperators: allowedOperators,
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
