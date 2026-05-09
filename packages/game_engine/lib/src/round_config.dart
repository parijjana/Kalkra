enum PoolType { standard, smallOnly, primesOnly, expanding }
enum TargetType { standard, ascending, fixed100, countdown }

abstract class RoundConstraint {
  String get description;
  bool validate(List<int> usedNumbers, List<String> operations);
}

class ForbiddenNumberConstraint extends RoundConstraint {
  final int forbiddenNumber;
  ForbiddenNumberConstraint(this.forbiddenNumber);

  @override
  String get description => 'You cannot use the number $forbiddenNumber!';

  @override
  bool validate(List<int> usedNumbers, List<String> operations) {
    return !usedNumbers.contains(forbiddenNumber);
  }
}

class MandatoryNumberConstraint extends RoundConstraint {
  final int mandatoryNumber;
  MandatoryNumberConstraint(this.mandatoryNumber);

  @override
  String get description => 'You MUST use the number $mandatoryNumber!';

  @override
  bool validate(List<int> usedNumbers, List<String> operations) {
    return usedNumbers.contains(mandatoryNumber);
  }
}

class OperationsBlackoutConstraint extends RoundConstraint {
  final List<String> blacklistedOperators;
  OperationsBlackoutConstraint(this.blacklistedOperators);

  @override
  String get description => 'Operators ${blacklistedOperators.join(", ")} are BANNED!';

  @override
  bool validate(List<int> usedNumbers, List<String> operations) {
    for (final op in operations) {
      if (blacklistedOperators.contains(op)) return false;
    }
    return true;
  }
}

class RoundConfig {
  final String title;
  final int durationSeconds;
  final PoolType poolType;
  final TargetType targetType;
  final List<RoundConstraint> constraints;
  final int rewardBump; // Extra points for exact match
  final bool isDualTarget;
  final bool allowNegative;
  final bool allowFractions;
  final bool allowMultipleSubmissions;
  final bool persistentTarget;

  const RoundConfig({
    required this.title,
    this.durationSeconds = 30,
    this.poolType = PoolType.standard,
    this.targetType = TargetType.standard,
    this.constraints = const [],
    this.rewardBump = 0,
    this.isDualTarget = false,
    this.allowNegative = false,
    this.allowFractions = false,
    this.allowMultipleSubmissions = false,
    this.persistentTarget = false,
  });

  static const classic = RoundConfig(title: 'Classic Round');
  
  static const smallNumbersOnly = RoundConfig(
    title: 'Small Numbers Only',
    poolType: PoolType.smallOnly,
    rewardBump: 2,
  );

  static const gauntlet = RoundConfig(
    title: 'The Gauntlet',
    durationSeconds: 20,
    rewardBump: 3,
  );

  static const forbiddenNumber = RoundConfig(
    title: 'Forbidden Number',
    rewardBump: 2,
  );

  static const twoTargets = RoundConfig(
    title: 'Two Targets',
    rewardBump: 10,
    isDualTarget: true,
  );

  static const mandatoryNumber = RoundConfig(
    title: 'Mandatory Number',
    rewardBump: 3,
  );

  static const operationsBlackout = RoundConfig(
    title: 'Operations Blackout',
    rewardBump: 3,
  );

  static const expandingPool = RoundConfig(
    title: 'Expanding Pool',
    poolType: PoolType.expanding,
    rewardBump: 5,
  );

  static const countdownMode = RoundConfig(
    title: 'Countdown Mode',
    targetType: TargetType.countdown,
    rewardBump: 5,
    durationSeconds: 60,
  );

  static const advanced = RoundConfig(
    title: 'Advanced Round',
    allowNegative: true,
    allowFractions: true,
    rewardBump: 10,
  );

  static const permutations = RoundConfig(
    title: 'Permutations',
    allowMultipleSubmissions: true,
    rewardBump: 5,
  );

  static const tunnelVision = RoundConfig(
    title: 'Tunnel Vision',
    persistentTarget: true,
    rewardBump: 5,
  );
}
