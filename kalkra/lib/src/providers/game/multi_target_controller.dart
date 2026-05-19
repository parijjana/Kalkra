import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import '../../services/sound_service.dart';
import '../providers.dart';

class MultiTargetState {
  final int secondsLeft;
  final String currentExpression;
  final List<int> usedIndices;
  final List<int> targets;
  final bool isRoundEnding;
  final Map<int, String> possibleSolutions;

  const MultiTargetState({
    this.secondsLeft = 90,
    this.currentExpression = '',
    this.usedIndices = const [],
    this.targets = const [],
    this.isRoundEnding = false,
    this.possibleSolutions = const {},
  });

  MultiTargetState copyWith({
    int? secondsLeft,
    String? currentExpression,
    List<int>? usedIndices,
    List<int>? targets,
    bool? isRoundEnding,
    Map<int, String>? possibleSolutions,
  }) {
    return MultiTargetState(
      secondsLeft: secondsLeft ?? this.secondsLeft,
      currentExpression: currentExpression ?? this.currentExpression,
      usedIndices: usedIndices ?? this.usedIndices,
      targets: targets ?? this.targets,
      isRoundEnding: isRoundEnding ?? this.isRoundEnding,
      possibleSolutions: possibleSolutions ?? this.possibleSolutions,
    );
  }
}

class MultiTargetController extends Notifier<MultiTargetState> {
  Timer? _timer;

  @override
  MultiTargetState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    return const MultiTargetState();
  }

  void initialize() {
    final round = ref.read(roundProvider);
    final solver = SolverEngine();
    final match = ref.read(matchProvider).value;
    
    // Find reachable target count (3 for Triple Threat, 2 for Double Danger)
    final int reachableCount = (match?.gameMode == GameMode.doubleDanger) ? 2 : 3;

    // Find solutions for the achievable targets
    final solutions = <int, String>{};
    for (int i = 0; i < reachableCount; i++) {
      if (i < round.targets.length) {
        final target = round.targets[i];
        final res = solver.solve(round.numbers, target);
        solutions[target] = res.expression ?? 'Unknown';
      }
    }

    state = state.copyWith(
      targets: List<int>.from(round.targets)..shuffle(),
      possibleSolutions: solutions,
      secondsLeft: 90,
      isRoundEnding: false,
      currentExpression: '',
      usedIndices: [],
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!timer.isActive) return;
      if (state.secondsLeft > 0) {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      } else {
        timer.cancel();
        _timer = null;
        endRound();
      }
    });
  }

  void onNumberTap(int index, int value) {
    if (state.isRoundEnding || state.usedIndices.contains(index)) return;
    final trimmed = state.currentExpression.trim();
    if (trimmed.isNotEmpty && RegExp(r'[\d\)]').hasMatch(trimmed[trimmed.length - 1])) return;

    SoundService().playTap();
    state = state.copyWith(
      currentExpression: state.currentExpression.isEmpty ? '$value' : '${state.currentExpression.trim()} $value',
      usedIndices: [...state.usedIndices, index],
    );
  }

  void onOperatorTap(String op) {
    if (state.isRoundEnding) {
      return;
    }
    final trimmed = state.currentExpression.trim();
    if (op == '(') {
      if (trimmed.isNotEmpty && !RegExp(r'[+\-*/(]$').hasMatch(trimmed)) {
        return;
      }
    } else if (op == ')') {
      if (trimmed.isEmpty || !RegExp(r'[\d)]$').hasMatch(trimmed)) {
        return;
      }
      if (')'.allMatches(trimmed).length >= '('.allMatches(trimmed).length) {
        return;
      }
    } else if (trimmed.isEmpty || !RegExp(r'[\d\)]$').hasMatch(trimmed)) {
      return;
    }

    SoundService().playTap();
    String nextExpr = trimmed.isEmpty ? op : '$trimmed $op';
    if (op != '(' && op != ')') nextExpr += ' ';
    state = state.copyWith(currentExpression: nextExpr);
  }

  void clear() => state = state.copyWith(currentExpression: '', usedIndices: [], isRoundEnding: false);

  void backspace() {
    if (state.isRoundEnding || state.currentExpression.isEmpty) return;
    final parts = state.currentExpression.trim().split(' ');
    if (parts.isEmpty) return;
    final lastPart = parts.removeLast();
    List<int> nextUsed = List.from(state.usedIndices);
    if (RegExp(r'^\d+$').hasMatch(lastPart) && nextUsed.isNotEmpty) nextUsed.removeLast();
    state = state.copyWith(currentExpression: parts.join(' '), usedIndices: nextUsed);
  }

  void endRound() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRoundEnding: true);
  }
}

final multiTargetControllerProvider = NotifierProvider.autoDispose<MultiTargetController, MultiTargetState>(MultiTargetController.new);
