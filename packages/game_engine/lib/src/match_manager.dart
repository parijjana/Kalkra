import 'dart:math';
import 'number_generator.dart';
import 'round_config.dart';
import 'solver_engine.dart';
import 'target_generator.dart';

enum JeopardyType {
  speedDemon,      // 50% less time
  operatorLockout, // Disables one random operator (+, -, *, /)
  doubleOrNothing, // Exact match gives 20 points, off-by-1 gives 0.
}

enum GameMode { practice, endless, progressive, multiplayer, tunnelVision, permutations, powersOf2, powersOf3 }

class MatchRoundData {
  final List<int> numbers;
  final List<int> targets;
  final JeopardyType? jeopardy;
  final String? lockedOperator;
  final RoundConfig config;
  final SolveResult bestSolution;

  MatchRoundData({
    required this.numbers,
    required this.targets,
    this.jeopardy,
    this.lockedOperator,
    required this.config,
    required this.bestSolution,
  });

  Map<String, dynamic> toJson() => {
    'numbers': numbers,
    'targets': targets,
    'jeopardy': jeopardy?.index,
    'lockedOperator': lockedOperator,
    'config': config.title, // Simplified for now
    'bestSolution': bestSolution.toJson(),
  };

  factory MatchRoundData.mock({
    List<int>? numbers,
    List<int>? targets,
    JeopardyType? jeopardy,
    String? lockedOperator,
    RoundConfig config = RoundConfig.classic,
  }) => MatchRoundData(
    numbers: numbers ?? [1, 2, 3, 4, 5, 10],
    targets: targets ?? [100],
    jeopardy: jeopardy,
    lockedOperator: lockedOperator,
    config: config,
    bestSolution: SolveResult(),
  );
}

class MatchManager {
  final int totalRounds;
  final bool jeopardyEnabled;
  final GameMode gameMode;
  final Difficulty initialDifficulty;
  int _currentRound = 1;
  int _lives = 3;
  List<MatchRoundData> _matchRounds = [];
  final Random _random;

  MatchManager({
    this.totalRounds = 5, 
    this.jeopardyEnabled = true,
    this.gameMode = GameMode.multiplayer,
    this.initialDifficulty = Difficulty.medium,
    int? seed,
  }) : _random = Random(seed);

  MatchManager.fromData({
    required this.totalRounds,
    required this.jeopardyEnabled,
    required this.gameMode,
    required this.initialDifficulty,
    required List<MatchRoundData> rounds,
    int? seed,
  }) : _random = Random(seed), _matchRounds = rounds;

  /// Static method intended to be run in a background isolate.
  static List<MatchRoundData> generateMatchData(({
    int totalRounds,
    bool jeopardyEnabled,
    GameMode gameMode,
    Difficulty initialDifficulty,
    int? seed,
    int startRoundIndex, // New: To track block context for Endless
  }) args) {
    final rounds = <MatchRoundData>[];
    final random = Random(args.seed);
    final numGen = NumberGenerator();
    final targetGen = TargetGenerator();
    final solver = SolverEngine();
    
    int? persistentTarget;
    Difficulty currentDifficulty = args.initialDifficulty;

    final roundsToGenerate = (args.gameMode == GameMode.endless) ? 10 : args.totalRounds;
    
    // Jeopardy Distribution Logic
    final jeopardyIndices = <int>{};
    if (args.jeopardyEnabled && args.gameMode != GameMode.progressive) {
      if (args.gameMode == GameMode.endless) {
        // Endless: 3 in first 10, then 4-5 per block
        final blockIndex = args.startRoundIndex ~/ 10;
        final count = (blockIndex == 0) ? 3 : (4 + random.nextInt(2));
        while (jeopardyIndices.length < count) {
          jeopardyIndices.add(random.nextInt(10));
        }
      } else {
        // Fixed Match: At least 1. 10 rounds -> 2 or 3.
        int jCount = 1;
        if (args.totalRounds == 10) {
          jCount = 2 + random.nextInt(2);
        }
        
        if (args.totalRounds > 1) {
          while (jeopardyIndices.length < jCount) {
            // Never jeopardy on Round 1
            final idx = 1 + random.nextInt(args.totalRounds - 1);
            jeopardyIndices.add(idx);
          }
        }
      }
    }

    for (int i = 1; i <= roundsToGenerate; i++) {
      final absoluteRoundIndex = args.startRoundIndex + i;
      final relativeIndex = i - 1;
      
      // 1. Determine Difficulty and Config for this round
      RoundConfig config = RoundConfig.classic;
      JeopardyType? jeopardy;
      String? lockedOp;

      if (args.gameMode == GameMode.progressive) {
        final setup = _getProgressiveSetupStatic(absoluteRoundIndex);
        currentDifficulty = setup.difficulty;
        config = setup.config;
      } else {
        // Scaling
        if (args.gameMode == GameMode.endless) {
          if (absoluteRoundIndex <= 5) {
            currentDifficulty = Difficulty.easy;
          } else if (absoluteRoundIndex <= 15) {
            currentDifficulty = Difficulty.medium;
          } else {
            currentDifficulty = Difficulty.hard;
          }
        } else {
          final progress = absoluteRoundIndex / args.totalRounds;
          if (progress <= 0.34) {
            currentDifficulty = Difficulty.easy;
          } else if (progress <= 0.67) {
            currentDifficulty = Difficulty.medium;
          } else {
            currentDifficulty = Difficulty.hard;
          }
        }

        if (args.gameMode == GameMode.permutations) {
          config = RoundConfig.permutations;
        } else if (args.gameMode == GameMode.tunnelVision) {
          config = RoundConfig.tunnelVision;
        } else if (args.gameMode == GameMode.powersOf2) {
          config = RoundConfig.powersOf2;
        } else if (args.gameMode == GameMode.powersOf3) {
          config = RoundConfig.powersOf3;
        }
        
        if (jeopardyIndices.contains(args.gameMode == GameMode.endless ? relativeIndex : absoluteRoundIndex - 1)) {
          jeopardy = JeopardyType.values[random.nextInt(JeopardyType.values.length)];
          if (jeopardy == JeopardyType.operatorLockout) {
            const ops = ['+', '-', '*', '/'];
            lockedOp = ops[random.nextInt(ops.length)];
          }
        }
      }

      // 2. Generate solvable data
      bool solvable = false;
      int attempts = 0;
      List<int> numbers = [];
      List<int> targets = [];
      SolveResult? bestSolution;

      final allowedOps = ['+', '-', '*', '/'];
      if (lockedOp != null) allowedOps.remove(lockedOp);

      while (!solvable && attempts < 20) {
        numbers = numGen.generatePool(
          difficulty: currentDifficulty, 
          seed: random.nextInt(1000000),
          poolType: config.poolType,
        );

        if (args.gameMode == GameMode.tunnelVision && persistentTarget != null) {
          targets = [persistentTarget];
          final res = solver.solve(numbers, persistentTarget, allowedOperators: allowedOps);
          if (res.foundExact) {
            solvable = true;
            bestSolution = res;
          }
        } else {
          targets = targetGen.generateReachableTargets(
            count: config.isDualTarget ? 2 : 1,
            pool: numbers,
            allowedOperators: allowedOps,
            difficulty: currentDifficulty,
            seed: random.nextInt(1000000),
            type: config.targetType,
            excludedTargets: rounds.expand((r) => r.targets).toSet(),
          );
          solvable = true;
          if (args.gameMode == GameMode.tunnelVision) persistentTarget = targets.first;
          bestSolution = solver.solve(numbers, targets.first, allowedOperators: allowedOps);
        }
        attempts++;
      }

      rounds.add(MatchRoundData(
        numbers: numbers,
        targets: targets,
        jeopardy: jeopardy,
        lockedOperator: lockedOp,
        config: config,
        bestSolution: bestSolution ?? SolveResult(),
      ));
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

  /// Pre-computes rounds for the match. 
  /// In fixed-length modes, generates everything. In Endless, generates a small buffer.
  void generateMatch({Difficulty initialDifficulty = Difficulty.easy}) {
    _matchRounds.clear();
    _matchRounds = generateMatchData((
      totalRounds: totalRounds,
      jeopardyEnabled: jeopardyEnabled,
      gameMode: gameMode,
      initialDifficulty: initialDifficulty,
      seed: _random.nextInt(1000000),
      startRoundIndex: 0,
    ));
  }

  MatchRoundData? get currentRoundData => (_currentRound <= _matchRounds.length) ? _matchRounds[_currentRound - 1] : null;

  int get currentRound => _currentRound;
  int get lives => _lives;
  
  bool get isMatchOver {
    if (gameMode == GameMode.endless) return _lives <= 0;
    return _currentRound > totalRounds;
  }

  void loseLife() {
    if (gameMode == GameMode.endless) {
      _lives--;
    }
  }

  void nextRound() {
    _currentRound++;
    
    // Refill Endless buffer if we are close to the end
    if (gameMode == GameMode.endless && _currentRound >= _matchRounds.length - 1) {
      final moreRounds = generateMatchData((
        totalRounds: 10, 
        jeopardyEnabled: jeopardyEnabled,
        gameMode: gameMode,
        initialDifficulty: Difficulty.hard,
        seed: _random.nextInt(1000000),
        startRoundIndex: _matchRounds.length,
      ));
      _matchRounds.addAll(moreRounds);
    }
  }

  void syncRound(int roundIndex) {
    _currentRound = roundIndex;
  }
}
