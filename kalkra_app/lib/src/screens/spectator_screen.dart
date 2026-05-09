import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import '../providers/hosted_session_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/global_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'results_screen.dart';

class SpectatorScreen extends ConsumerStatefulWidget {
  const SpectatorScreen({super.key});

  @override
  ConsumerState<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends ConsumerState<SpectatorScreen> with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsLeft = 0;

  bool _isRoundEnding = false;
  JeopardyType _nextJeopardy = JeopardyType.speedDemon;

  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _startTimer();
    _entranceController.forward();
    
    final round = ref.read(roundProvider);
    _secondsLeft = round.jeopardyType == JeopardyType.speedDemon ? 30 : 60;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _onTimeUp();
      }
    });
  }

  Future<void> _onTimeUp() async {
    if (_isRoundEnding) return;
    _isRoundEnding = true;
    _timer?.cancel();

    final round = ref.read(roundProvider);
    final transport = ref.read(transportProvider);
    final session = ref.read(sessionProvider);
    final match = ref.read(matchProvider).value;

    round.endRound();

    if (transport is LanHostTransport) {
      final target = round.target ?? 0;
      final validator = SubmissionValidator();
      final playerResults = <String, Map<String, dynamic>>{};
      
      // 1. Validate all submissions
      for (final id in session.players.keys) {
        final p = session.players[id]!;
        final expression = p.lastExpression ?? '';
        final validation = validator.validate(expression, round.numbers);
        
        int? val;
        int proximity = 1000000;
        
        if (validation.isValid && validation.value != null) {
          val = validation.value!.toInt();
          proximity = (target - val).abs();
        }

        playerResults[id] = {
          'name': p.name,
          'expression': expression,
          'value': val,
          'proximity': proximity == 1000000 ? null : proximity,
          'teamId': p.teamId,
        };
      }

      // 2. Determine best result per team
      final teamBestPoints = <int, int>{}; // teamId -> points

      for (int tId = 1; tId <= 4; tId++) {
        final teamPlayers = session.players.entries.where((e) => e.value.teamId == tId).map((e) => e.key).toList();
        if (teamPlayers.isEmpty) continue;

        int minProx = 1000000;
        int? bestVal;

        for (final pId in teamPlayers) {
          final res = playerResults[pId]!;
          final prox = res['proximity'] as int?;
          if (prox != null && prox < minProx) {
            minProx = prox;
            bestVal = res['value'];
          }
        }

        if (minProx < 1000000) {
          final scoreKeeper = ScoreKeeper();
          final pts = scoreKeeper.calculateScore(target: target, result: bestVal!, jeopardy: round.jeopardyType);
          teamBestPoints[tId] = pts;
          session.awardTeamPoints(tId, pts);
        }
      }

      Map<String, int>? eloShifts;
      bool isMatchOver = false;
      if (match != null) {
        isMatchOver = match.isMatchOver;
        if (isMatchOver) {
          final playerElos = session.players.map((id, p) => MapEntry(id, p.currentElo));
          String? winnerId; int maxScore = -1;
          for (final entry in session.players.entries) {
            if (entry.value.cumulativeScore > maxScore) { maxScore = entry.value.cumulativeScore; winnerId = entry.key; }
          }
          if (winnerId != null) { eloShifts = EloCalculator.calculateMultiplayerShifts(playerElos: playerElos, winnerId: winnerId); }
        }
      }

      await transport.sendEvent(GameEvent(type: GameEventType.roundResults, payload: {
        'playerResults': playerResults,
        'teamPoints': teamBestPoints.map((k, v) => MapEntry(k.toString(), v)),
        'teamTotalScores': session.teamScores.map((k, v) => MapEntry(k.toString(), v)),
        'bestSolution': round.bestSolution?.toJson(),
        'eloShifts': eloShifts,
        'isMatchOver': isMatchOver
      }));

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ResultsScreen(
            playerExpression: '', 
            playerValue: 0, 
            playerPoints: 0, 
            multiplayerResults: playerResults,
            teamPoints: teamBestPoints,
            teamTotalScores: session.teamScores,
            eloShifts: eloShifts
          ),
        ));
      }
    }
  }

  void _kickPlayer(String id) {
    ref.read(transportProvider).kickPlayer(id);
  }

  void _banPlayer(String id, String? deviceId) {
    if (deviceId != null) ref.read(hostedSessionProvider.notifier).banDevice(deviceId);
    ref.read(transportProvider).kickPlayer(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Player banned and removed.')));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('SpectatorScreen');
    });

    // Listen for early round end signal
    ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.type == GameEventType.roundEnded) {
          _onTimeUp();
        }
      });
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = ref.watch(roundProvider);
    final session = ref.watch(sessionProvider);
    final match = ref.watch(matchProvider).value;
    final nextRoundJeopardy = ref.watch(jeopardyOverrideProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.type == GameEventType.submissionReceived) {
           final playerId = event.payload['playerId'] as String;
           final expression = event.payload['expression'] as String;
           session.recordSubmission(playerId, expression, 0);
           
           // Early Termination Check
           final assignedPlayers = session.players.values.where((p) => p.teamId > 0);
           if (assignedPlayers.isNotEmpty && assignedPlayers.every((p) => p.lastExpression != null)) {
             _onTimeUp();
           }
        } else if (event.type == GameEventType.roundStarted) {
           // ... handle round started
        }
      });
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: isDesktop ? const TopNavBar(activeId: 'SpectatorScreen') : AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/app_icon.svg',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            Flexible(child: Text('COMMAND CENTER • ROUND ${match?.currentRound ?? 1}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16))),
          ],
        ),
        centerTitle: true,
        backgroundColor: colorScheme.secondary,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: VectorBackground(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24), 
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow, 
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)), 
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 10))]
              ), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                children: [
                  Column(children: [Text('TARGET', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10)), Text('${round.target}', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary))]), 
                  Container(width: 1, height: 40, color: colorScheme.onSurface.withValues(alpha: 0.1)), 
                  Column(children: [Text('TIME LEFT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10)), Text('$_secondsLeft', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: _secondsLeft < 10 ? Colors.red : colorScheme.onSurface))])
                ]
              )
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24), 
              child: Container(
                padding: const EdgeInsets.all(24), 
                decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(32), border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1))), 
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.amber), 
                        const SizedBox(width: 12), 
                        Text('HOST CONTROLS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.primary)), 
                        const Spacer(), 
                        Switch(value: nextRoundJeopardy, onChanged: (v) => ref.read(jeopardyOverrideProvider.notifier).setOverride(v), activeThumbColor: colorScheme.primary), 
                        Text('JEOPARDY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.5)))
                      ]
                    ),
                    if (nextRoundJeopardy) ...[
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: JeopardyType.values.map((type) {
                          final isActive = _nextJeopardy == type;
                          return ChoiceChip(
                            label: Text(type.name.toUpperCase()),
                            selected: isActive,
                            onSelected: (selected) {
                              if (selected) setState(() => _nextJeopardy = type);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                )
              )
            ),
            const SizedBox(height: 32),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.0), itemCount: session.players.length, itemBuilder: (context, index) {
              final id = session.players.keys.elementAt(index);
              final player = session.players[id]!;
              final hasSubmitted = player.lastExpression != null;
              final teamColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];
              final teamColor = player.teamId > 0 ? teamColors[player.teamId - 1] : Colors.grey;

              return Container(decoration: BoxDecoration(color: hasSubmitted ? Colors.green.withValues(alpha: 0.1) : colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: hasSubmitted ? Colors.green.withValues(alpha: 0.3) : teamColor.withValues(alpha: 0.3), width: 2), boxShadow: [BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))]), child: Stack(children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Center(child: CircleAvatar(backgroundColor: hasSubmitted ? Colors.green : teamColor.withValues(alpha: 0.1), child: hasSubmitted ? const Icon(Icons.check_rounded, color: Colors.white) : Text(player.name[0].toUpperCase(), style: TextStyle(color: teamColor, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 12),
                  Text(player.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: colorScheme.onSurface)),
                  Text('TEAM ${player.teamId}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: teamColor)),
                  Text(hasSubmitted ? 'SUBMITTED' : 'THINKING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasSubmitted ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.4))),
                ]),
                if (id != 'host') Positioned(top: 4, right: 4, child: PopupMenuButton(icon: Icon(Icons.more_vert_rounded, size: 18, color: colorScheme.onSurface), itemBuilder: (context) => [
                  PopupMenuItem(child: const Text('KICK'), onTap: () => _kickPlayer(id)),
                  PopupMenuItem(child: const Text('BAN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: () => _banPlayer(id, player.deviceId)),
                ]))
              ]));
            }))),
            Padding(padding: const EdgeInsets.all(32), child: SizedBox(width: double.infinity, height: 64, child: ElevatedButton(onPressed: _onTimeUp, style: ElevatedButton.styleFrom(backgroundColor: colorScheme.onSurface, foregroundColor: colorScheme.surface), child: const Text('FORCE END ROUND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4))))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _timer?.cancel(); _entranceController.dispose(); super.dispose(); }
}
