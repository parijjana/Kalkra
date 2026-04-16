enum PoolType { standard, smallOnly, primesOnly }
enum TargetType { standard, ascending, fixed100 }

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

class RoundConfig {
  final String title;
  final int durationSeconds;
  final PoolType poolType;
  final TargetType targetType;
  final List<RoundConstraint> constraints;
  final int rewardBump; // Extra points for exact match

  const RoundConfig({
    required this.title,
    this.durationSeconds = 30,
    this.poolType = PoolType.standard,
    this.targetType = TargetType.standard,
    this.constraints = const [],
    this.rewardBump = 0,
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
}
