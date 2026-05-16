import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/providers.dart';
import '../widgets/vector_background.dart';
import '../widgets/global_drawer.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/staging/staging_widgets.dart';
import 'game_screen.dart';
import 'spectator_screen.dart';

class StagingScreen extends ConsumerStatefulWidget {
  const StagingScreen({super.key});

  @override
  ConsumerState<StagingScreen> createState() => _StagingScreenState();
}

class _StagingScreenState extends ConsumerState<StagingScreen> {
  String? _connectionString;

  @override
  void initState() {
    super.initState();
    _loadConnectionInfo();
  }

  Future<void> _loadConnectionInfo() async {
    final transport = ref.read(transportProvider);
    if (transport is LanHostTransport) {
      final info = NetworkInfo();
      final ip = await info.getWifiIP() ?? '127.0.0.1';
      setState(() {
        _connectionString = 'ws://$ip:${transport.port}';
      });
    }
  }

  void _assignTeam(String pId, int tId) {
    ref
        .read(transportProvider)
        .sendEvent(
          GameEvent(
            type: GameEventType.teamAssignment,
            payload: {'playerId': pId, 'teamId': tId},
          ),
        );
  }

  void _renameTeam(int tId, String name) {
    ref
        .read(transportProvider)
        .sendEvent(
          GameEvent(
            type: GameEventType.teamRename,
            payload: {'teamId': tId, 'name': name},
          ),
        );
  }

  void _shuffle() {
    final session = ref.read(sessionProvider);
    final ids =
        session.players.entries
            .where((e) => e.value.teamId == 0)
            .map((e) => e.key)
            .toList()
          ..shuffle();
    final count = session.players.length > 3 ? 4 : 2;
    for (int i = 0; i < ids.length; i++) {
      _assignTeam(ids[i], (i % count) + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionUpdateProvider);
    final transport = ref.watch(transportProvider);
    final session = ref.watch(sessionProvider);
    final isHost = transport is LanHostTransport;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<MatchStatus>(matchStatusProvider, (p, n) {
      if (n == MatchStatus.playing) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (c) => ref.read(isHostOnlyProvider)
                ? const SpectatorScreen()
                : const GameScreen(),
          ),
        );
      }
    });

    if (isHost) _autoAssign(session);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: _buildAppBar(colorScheme, isDesktop),
      body: VectorBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (!isDesktop && _connectionString != null)
                      QRBadge(connectionString: _connectionString!),
                    LobbyStatusHeader(
                      colorScheme: colorScheme,
                      session: session,
                      isHost: isHost,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: isDesktop
                          ? _buildDesktopLayout(session, isHost, colorScheme)
                          : _buildMobileLayout(session, isHost, colorScheme),
                    ),
                  ],
                ),
              ),
            ),
            LobbyFooter(
              isHost: isHost,
              colorScheme: colorScheme,
              isReady: session.players[transport.myId]?.isReady ?? false,
              canStart: session.allAssignedReady,
              onToggleReady: () => transport.sendEvent(
                GameEvent(
                  type: GameEventType.playerReady,
                  payload: {
                    'ready':
                        !(session.players[transport.myId]?.isReady ?? false),
                  },
                ),
              ),
              onStartMatch: _startMatch,
              onShuffle: _shuffle,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme, bool isDesktop) =>
      AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/app_icon.svg',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'ARENA LOBBY',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
            ),
          ],
        ),
        centerTitle: !isDesktop,
        backgroundColor: colorScheme.secondary,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (c) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(c).openDrawer(),
          ),
        ),
      );

  Widget _buildMobileLayout(
    SessionManager session,
    bool isHost,
    ColorScheme colorScheme,
  ) => Column(
    children: [
      SizedBox(
        height: 180,
        child: PlayerPool(
          session: session,
          isHost: isHost,
          colorScheme: colorScheme,
          onAssign: _assignTeam,
        ),
      ),
      const SizedBox(height: 32),
      ...List.generate(
        session.players.length > 3 ? 4 : 2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TeamZone(
            teamId: i + 1,
            session: session,
            isHost: isHost,
            colorScheme: colorScheme,
            onAssign: _assignTeam,
            onRename: _renameTeam,
          ),
        ),
      ),
    ],
  );

  Widget _buildDesktopLayout(
    SessionManager session,
    bool isHost,
    ColorScheme colorScheme,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 280,
        height: 600,
        child: PlayerPool(
          session: session,
          isHost: isHost,
          colorScheme: colorScheme,
          onAssign: _assignTeam,
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TeamZone(
                    teamId: 1,
                    session: session,
                    isHost: isHost,
                    colorScheme: colorScheme,
                    onAssign: _assignTeam,
                    onRename: _renameTeam,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TeamZone(
                    teamId: 2,
                    session: session,
                    isHost: isHost,
                    colorScheme: colorScheme,
                    onAssign: _assignTeam,
                    onRename: _renameTeam,
                  ),
                ),
                if (_connectionString != null) ...[
                  const SizedBox(width: 24),
                  QRBadge(
                    connectionString: _connectionString!,
                    isDesktop: true,
                  ),
                ],
              ],
            ),
            if (session.players.length > 3) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TeamZone(
                      teamId: 3,
                      session: session,
                      isHost: isHost,
                      colorScheme: colorScheme,
                      onAssign: _assignTeam,
                      onRename: _renameTeam,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TeamZone(
                      teamId: 4,
                      session: session,
                      isHost: isHost,
                      colorScheme: colorScheme,
                      onAssign: _assignTeam,
                      onRename: _renameTeam,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );

  void _autoAssign(SessionManager session) {
    final unassigned = session.players.entries
        .where((e) => e.value.teamId == 0)
        .toList();
    if (unassigned.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final count = session.players.length;
        if (count == 7) {
          final ids = session.players.keys.toList();
          for (int i = 0; i < ids.length; i++) {
            _assignTeam(ids[i], (i % 4) + 1);
          }
        } else {
          for (final p in unassigned) {
            int best = 1;
            int min = 100;
            for (int t = 1; t <= (count > 6 ? 4 : 2); t++) {
              final c = session.players.values
                  .where((pl) => pl.teamId == t)
                  .length;
              if (c < min) {
                min = c;
                best = t;
              }
            }
            _assignTeam(p.key, best);
          }
        }
      });
    }
  }

  void _startMatch() async {
    final transport = ref.read(transportProvider);
    final match = ref.read(matchProvider).value;
    final round = ref.read(roundProvider);
    final session = ref.read(sessionProvider);

    if (match == null) return;
    match.generateMatch();

    final roundData = match.currentRoundData;
    if (roundData == null) return;

    round.startRound(data: roundData);
    session.resetRoundData();

    await transport.sendEvent(
      GameEvent(
        type: GameEventType.hostStartedMatch,
        payload: {
          'targets': roundData.targets,
          'target': roundData.targets.first,
          'numbers': roundData.numbers,
          'difficulty': 1,
          'config': roundData.config.title,
          'jeopardy': roundData.jeopardy?.index,
          'lockedOperator': roundData.lockedOperator,
          'totalRounds': match.totalRounds,
          'gameMode': match.gameMode.index,
          'currentRound': match.currentRound,
        },
      ),
    );
  }
}
