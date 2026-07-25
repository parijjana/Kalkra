import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import '../providers/providers.dart';
import '../widgets/vector_background.dart';
import '../widgets/game/game_widgets.dart';
import '../widgets/global_drawer.dart';
import '../services/sound_service.dart';
import 'results_screen.dart';
import 'main_screen.dart';

class MultiTargetScreen extends ConsumerStatefulWidget {
  const MultiTargetScreen({super.key});

  @override
  ConsumerState<MultiTargetScreen> createState() => _MultiTargetScreenState();
}

class _MultiTargetScreenState extends ConsumerState<MultiTargetScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(multiTargetControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _onExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'EXIT MISSION?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('Your progress in this round will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'EXIT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    final state = ref.read(multiTargetControllerProvider);
    if (state.currentExpression.isEmpty || state.isRoundEnding) return;

    final round = ref.read(roundProvider);
    final validation = SubmissionValidator().validate(
      state.currentExpression,
      round.numbers,
    );

    if (validation.isValid && validation.value != null) {
      final resultVal = validation.value!.toInt();
      final match = ref.read(matchProvider).value;
      final int reachableCount = (match?.gameMode == GameMode.doubleDanger)
          ? 2
          : 3;
      final achievable = round.targets.take(reachableCount).toList();

      if (achievable.contains(resultVal)) {
        SoundService().playSuccess();
        _navigateToResults(true, resultVal);
      } else {
        SoundService().playError();
        _navigateToResults(false, resultVal);
      }
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('INVALID EXPRESSION')));
    }
  }

  void _navigateToResults(bool success, int? guessedValue) {
    final state = ref.read(multiTargetControllerProvider);
    final round = ref.read(roundProvider);
    final match = ref.read(matchProvider).value;
    final session = ref.read(sessionProvider);

    ref.read(multiTargetControllerProvider.notifier).endRound();

    final int reachableCount = (match?.gameMode == GameMode.doubleDanger)
        ? 2
        : 3;
    final achievable = round.targets.take(reachableCount).toList()
      ..sort((a, b) => b.compareTo(a));

    int points = 0;
    if (success && guessedValue != null) {
      if (guessedValue == achievable[0]) {
        points = 10;
      } else if (guessedValue == achievable[1]) {
        points = 7;
      } else if (reachableCount > 2 && guessedValue == achievable[2]) {
        points = 5;
      }
    }

    // Record Score
    session.recordSubmission('solo', state.currentExpression, points);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            playerExpression: state.currentExpression,
            playerValue: guessedValue,
            playerPoints: points,
            tripleThreatSolutions: state.possibleSolutions,
            tripleThreatGuessed: guessedValue,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundService().ensureMusicPlaying();
    });

    final state = ref.watch(multiTargetControllerProvider);
    final controller = ref.read(multiTargetControllerProvider.notifier);
    final round = ref.watch(roundProvider);
    final match = ref.watch(matchProvider).value;
    final session = ref.watch(sessionProvider);

    final myScore = session.getPlayerScore('solo');

    ref.listen<MultiTargetState>(multiTargetControllerProvider, (prev, next) {
      if (next.isRoundEnding && !(prev?.isRoundEnding ?? false)) {
        _navigateToResults(false, null);
      }
    });

    final isDoubleDanger = match?.gameMode == GameMode.doubleDanger;
    final title = isDoubleDanger ? 'DOUBLE DANGER' : 'TRIPLE THREAT';

    return Scaffold(
      drawer: const GlobalDrawer(),
      appBar: GameHeader(
        roundText: title,
        myScore: myScore,
        secondsLeft: state.secondsLeft,
        onExit: _onExit,
        onClear: controller.clear,
      ),
      body: VectorBackground(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              children: [
                if (state.targets.isNotEmpty)
                  Expanded(
                    flex: 10,
                    child: TargetGrid(
                      targets: state.targets,
                      onTargetTap: (_) {},
                    ),
                  ),

                const Spacer(flex: 1),

                FittedBox(
                  child: NumbersSection(
                    numbers: round.numbers,
                    usedIndices: state.usedIndices,
                    onNumberTap: controller.onNumberTap,
                    entranceAnimation: _entranceController,
                    focusedIndex: -1,
                  ),
                ),
                const SizedBox(height: 12),
                ExpressionSection(
                  currentExpression: state.currentExpression,
                  onBackspace: controller.backspace,
                ),

                const SizedBox(height: 12),

                ControlsSection(
                  onOperatorTap: controller.onOperatorTap,
                  onSubmit: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
