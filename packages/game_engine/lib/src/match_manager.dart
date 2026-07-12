import 'dart:math';
import 'number_generator.dart';
import 'round_config.dart';
import 'solver_engine.dart';
import 'target_generator.dart';

enum WildcardType {
  speedDemon,      // 50% less time
  operatorLockout, // Disables one random operator (+, -, *, /)
  doubleOrNothing, // Exact match gives 20 points, off-by-1 gives 0.
}

enum GameMode { practice, endless, progressive, multiplayer, tunnelVision, permutations, powersOf2, tripleThreat, doubleDanger }

class MatchRoundData {
  final List<int> numbers;
  final List<int> targets;
  final WildcardType? wildcard;
  final String? lockedOperator;
  final RoundConfig config;
  final SolveResult bestSolution;

  MatchRoundData({
    required this.numbers,
    required this.targets,
    this.wildcard,
    this.lockedOperator,
    required this.config,
    required this.bestSolution,
  });

  Map<String, dynamic> toJson() => {
    'numbers': numbers,
    'targets': targets,
    'jeopardy': wildcard?.index,
    'lockedOperator': lockedOperator,
    'config': config.title, // Simplified for now
    'bestSolution': bestSolution.toJson(),
  };

  factory MatchRoundData.mock({
    List<int>? numbers,
    List<int>? targets,
    WildcardType? wildcard,
    String? lockedOperator,
    RoundConfig config = RoundConfig.classic,
  }) => MatchRoundData(
    numbers: numbers ?? [1, 2, 3, 4, 5, 10],
    targets: targets ?? [100],
    wildcard: wildcard,
    lockedOperator: lockedOperator,
    config: config,
    bestSolution: SolveResult(),
  );
}

class MatchManager {
  final int totalRounds;
  final bool wildcardEnabled;
  final GameMode gameMode;
  final Difficulty initialDifficulty;
  int _currentRound = 1;
  int _lives = 3;
  List<MatchRoundData> _matchRounds = [];
  final Random _random;

  MatchManager({
    this.totalRounds = 5, 
    this.wildcardEnabled = true,
    this.gameMode = GameMode.multiplayer,
    this.initialDifficulty = Difficulty.medium,
    int? seed,
  }) : _random = Random(seed);

  MatchManager.fromData({
    required this.totalRounds,
    required this.wildcardEnabled,
    required this.gameMode,
    required this.initialDifficulty,
    required List<MatchRoundData> rounds,
    int? seed,
  }) : _random = Random(seed), _matchRounds = rounds;

  /// Static method intended to be run in a background isolate.
  static List<MatchRoundData> generateMatchData(({
    int totalRounds,
    bool wildcardEnabled,
    GameMode gameMode,
    Difficulty initialDifficulty,
    int? seed,
    int startRoundIndex, 
  }) args) {
    final rounds = <MatchRoundData>[];
    final random = Random(args.seed);
    final numGen = NumberGenerator();
    final targetGen = TargetGenerator();
    final solver = SolverEngine();
    
    int? persistentTarget;
    Difficulty currentDifficulty = args.initialDifficulty;

    // Wildcard Distribution Logic
    final wildcardIndices = <int>{};
    if (args.wildcardEnabled && args.gameMode != GameMode.progressive) {
      if (args.gameMode == GameMode.endless) {
        final blockIndex = args.startRoundIndex ~/ 10;
        final count = (blockIndex == 0) ? 3 : (4 + random.nextInt(2));
        while (wildcardIndices.length < count) wildcardIndices.add(random.nextInt(10));
      } else {
        int jCount = args.totalRounds == 10 ? 2 + random.nextInt(2) : 1;
        if (args.totalRounds > 1) {
          while (wildcardIndices.length < jCount) {
            final idx = 1 + random.nextInt(args.totalRounds - 1);
            wildcardIndices.add(idx);
          }
        }
      }
    }

    final int roundsToGen = (args.gameMode == GameMode.endless) ? 10 : args.totalRounds;

    for (int i = 1; i <= roundsToGen; i++) {
      final absoluteRoundIndex = args.startRoundIndex + i;
      final relativeIndex = i - 1;
      
      RoundConfig config = RoundConfig.classic;
      WildcardType? wildcard;
      String? lockedOp;

      if (args.gameMode == GameMode.progressive) {
        final setup = _getProgressiveSetupStatic(absoluteRoundIndex);
        currentDifficulty = setup.difficulty;
        config = setup.config;
      } else {
        if (args.gameMode == GameMode.endless) {
          if (absoluteRoundIndex <= 5) currentDifficulty = Difficulty.easy;
          else if (absoluteRoundIndex <= 15) currentDifficulty = Difficulty.medium;
          else currentDifficulty = Difficulty.hard;
        } else {
          final progress = absoluteRoundIndex / args.totalRounds;
          if (progress <= 0.34) currentDifficulty = Difficulty.easy;
          else if (progress <= 0.67) currentDifficulty = Difficulty.medium;
          else currentDifficulty = Difficulty.hard;
        }

        if (args.gameMode == GameMode.permutations) config = RoundConfig.permutations;
        else if (args.gameMode == GameMode.tunnelVision) config = RoundConfig.tunnelVision;
        else if (args.gameMode == GameMode.powersOf2) config = RoundConfig.powersOf2;
        else if (args.gameMode == GameMode.tripleThreat) config = RoundConfig.tripleThreat;
        else if (args.gameMode == GameMode.doubleDanger) config = RoundConfig.doubleDanger;
        
        if (wildcardIndices.contains(args.gameMode == GameMode.endless ? relativeIndex : absoluteRoundIndex - 1)) {
          wildcard = WildcardType.values[random.nextInt(WildcardType.values.length)];
          if (wildcard == WildcardType.operatorLockout) lockedOp = ['+', '-', '*', '/'][random.nextInt(4)];
        }
      }

      bool solvable = false; int attempts = 0;
      List<int> numbers = []; List<int> targets = []; SolveResult? bestSolution;
      final allowedOps = ['+', '-', '*', '/']; if (lockedOp != null) allowedOps.remove(lockedOp);

      while (!solvable && attempts < 20) {
        numbers = numGen.generatePool(difficulty: currentDifficulty, seed: random.nextInt(1000000), poolType: config.poolType);
        if (args.gameMode == GameMode.tripleThreat) {
          targets = targetGen.generateTripleThreatTargets(pool: numbers, allowedOperators: allowedOps, difficulty: currentDifficulty, seed: random.nextInt(1000000));
          solvable = true;
          bestSolution = SolveResult();
        } else if (args.gameMode == GameMode.doubleDanger) {
          targets = targetGen.generateDoubleDangerTargets(pool: numbers, allowedOperators: allowedOps, difficulty: currentDifficulty, seed: random.nextInt(1000000));
          solvable = true;
          bestSolution = SolveResult();
        } else if (args.gameMode == GameMode.tunnelVision && persistentTarget != null) {
          targets = [persistentTarget!];
          final res = solver.solve(numbers, persistentTarget!, allowedOperators: allowedOps);
          if (res.foundExact) { solvable = true; bestSolution = res; }
        } else {
          targets = targetGen.generateReachableTargets(count: config.isDualTarget ? 2 : 1, pool: numbers, allowedOperators: allowedOps, difficulty: currentDifficulty, seed: random.nextInt(1000000), type: config.targetType, excludedTargets: rounds.expand((r) => r.targets).toSet());
          solvable = true;
          if (args.gameMode == GameMode.tunnelVision) persistentTarget = targets.first;
          bestSolution = solver.solve(numbers, targets.first, allowedOperators: allowedOps);
        }
        attempts++;
      }
      rounds.add(MatchRoundData(numbers: numbers, targets: targets, wildcard: wildcard, lockedOperator: lockedOp, config: config, bestSolution: bestSolution ?? SolveResult()));
    }
    return rounds;
  }

  static ({Difficulty difficulty, RoundConfig config}) _getProgressiveSetupStatic(int round) {
    switch (round) {
      case 1:
      case 2: return (difficulty: Difficulty.easy, config: RoundConfig.classic);
      case 3: return (difficulty: Difficulty.medium, config: RoundConfig.gauntlet);
      case 4: return (difficulty: Difficulty.medium, config: RoundConfig.forbiddenNumber);
      case 5: return (difficulty: Difficulty.medium, config: RoundConfig.twoTargets);
      case 6: return (difficulty: Difficulty.hard, config: RoundConfig.expandingPool);
      case 7: return (difficulty: Difficulty.hard, config: RoundConfig.mandatoryNumber);
      case 8: return (difficulty: Difficulty.hard, config: RoundConfig.countdownMode);
      default: return (difficulty: Difficulty.hard, config: RoundConfig.classic);
    }
  }

  void generateMatch({Difficulty initialDifficulty = Difficulty.easy}) {
    _matchRounds = generateMatchData((totalRounds: totalRounds, wildcardEnabled: wildcardEnabled, gameMode: gameMode, initialDifficulty: initialDifficulty, seed: _random.nextInt(1000000), startRoundIndex: 0));
  }

  void appendRounds(List<MatchRoundData> newRounds) {
    _matchRounds.addAll(newRounds);
  }

  MatchRoundData? get currentRoundData => (_currentRound <= _matchRounds.length) ? _matchRounds[_currentRound - 1] : null;
  int get currentRound => _currentRound;
  int get lives => _lives;
  bool get isMatchOver => gameMode == GameMode.endless ? _lives <= 0 : _currentRound > totalRounds;
  
  void loseLife() { if (gameMode == GameMode.endless) _lives--; }
  void nextRound() {
    _currentRound++;
    if (gameMode == GameMode.endless && _currentRound >= _matchRounds.length - 1) {
      final moreRounds = generateMatchData((totalRounds: 10, wildcardEnabled: wildcardEnabled, gameMode: gameMode, initialDifficulty: Difficulty.hard, seed: _random.nextInt(1000000), startRoundIndex: _matchRounds.length));
      _matchRounds.addAll(moreRounds);
    }
  }
  void syncRound(int roundIndex) { _currentRound = roundIndex; }
}
