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
    } else if (type == TargetType.powersOf2 || type == TargetType.powersOf3) {
      switch (difficulty) {
        case Difficulty.easy: minT = 100; maxT = 999; break;
        case Difficulty.medium: minT = 1000; maxT = 9999; break;
        case Difficulty.hard: minT = 1000; maxT = 9999; break;
      }
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

    final powerPool = type == TargetType.powersOf2 
        ? [128, 256, 512, 1024, 2048, 4096, 8192]
        : (type == TargetType.powersOf3 ? [243, 729, 2187, 6561] : null);

    final attempts = (powerPool != null) ? powerPool.length * 2 : 20;

    for (int i = 0; i < attempts; i++) {
      int candidate;
      if (powerPool != null) {
        candidate = powerPool[random.nextInt(powerPool.length)];
        // Filter by range
        if (candidate < minT || candidate > maxT) continue;
      } else {
        candidate = minT + random.nextInt(maxT - minT + 1);
      }
      
      if (excludedTargets != null && excludedTargets.contains(candidate)) continue;

      final res = _solver.solve(pool, candidate, allowedOperators: allowedOperators);
      if (res.foundExact) return candidate;

      final resultVal = res.bestValue ?? pool.first;
      
      // If themed, resultVal must also be a power of N
      if (powerPool != null && !powerPool.contains(resultVal)) continue;

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

    // Themed Fallback: Random power within range
    if (powerPool != null) {
      final inRange = powerPool.where((p) => p >= minT && p <= maxT).toList();
      if (inRange.isNotEmpty) return inRange[random.nextInt(inRange.length)];
    }

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
