import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/game_providers.dart';
import '../widgets/vector_background.dart';
import '../widgets/global_drawer.dart';
import '../widgets/responsive_layout.dart';
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

  @override
  Widget build(BuildContext context) {
    // Watch session updates to trigger rebuilds
    ref.watch(sessionUpdateProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transport = ref.watch(transportProvider);
    final session = ref.watch(sessionProvider);
    final isHost = transport is LanHostTransport;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    
    final totalPlayers = session.players.length;
    final showAdvancedTeams = totalPlayers > 3;

    // Listen for match status changes for auto-navigation
    ref.listen<MatchStatus>(matchStatusProvider, (prev, next) {
      if (next == MatchStatus.playing) {
        final isSpectating = ref.read(isHostOnlyProvider);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => isSpectating ? const SpectatorScreen() : const GameScreen(),
          ),
        );
      }
    });

    // Auto-assignment logic (Host only)
    if (isHost) {
      final unassigned = session.players.entries.where((e) => e.value.teamId == 0).toList();
      if (unassigned.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final totalCount = session.players.length;
          final targetTeamCount = totalCount > 6 ? 4 : 2;
          
          if (totalCount == 7) {
             // Rebalance everything across 4 teams
             final allPlayers = session.players.keys.toList();
             for (int i = 0; i < allPlayers.length; i++) {
                _assignTeam(allPlayers[i], (i % 4) + 1);
             }
          } else {
             // Assign only the new arrivals
             for (final player in unassigned) {
                // Find team with fewest players
                int bestTeam = 1;
                int minCount = 100;
                for (int t = 1; t <= targetTeamCount; t++) {
                   final count = session.players.values.where((p) => p.teamId == t).length;
                   if (count < minCount) {
                      minCount = count;
                      bestTeam = t;
                   }
                }
                _assignTeam(player.key, bestTeam);
             }
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/app_icon.svg',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            const Flexible(child: Text('ARENA LOBBY', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4))),
          ],
        ),
        centerTitle: !isDesktop,
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 1. Join QR Hub (Mobile: Top, Desktop: Row)
                    if (!isDesktop && _connectionString != null) _buildMobileQRHeader(colorScheme),
                    
                    // 2. Lobby Status Header
                    _buildStatusHeader(colorScheme, session, isHost),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: isDesktop 
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Player Pool
                              SizedBox(
                                width: 280,
                                height: 600,
                                child: _buildPlayerPool(session, isHost, colorScheme),
                              ),
                              const SizedBox(width: 24),
                              // Team Grids + Desktop QR
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildTeamRow([1, 2], session, isHost, colorScheme),
                                        ),
                                        if (_connectionString != null) ...[
                                          const SizedBox(width: 24),
                                          _buildDesktopQRBadge(colorScheme),
                                        ],
                                      ],
                                    ),
                                    if (showAdvancedTeams) ...[
                                      const SizedBox(height: 24),
                                      _buildTeamRow([3, 4], session, isHost, colorScheme),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // Compact Pool for Mobile
                              SizedBox(
                                height: 180,
                                child: _buildPlayerPool(session, isHost, colorScheme),
                              ),
                              const SizedBox(height: 32),
                              _buildTeamZone(1, session, isHost, colorScheme, minHeight: 140),
                              const SizedBox(height: 16),
                              _buildTeamZone(2, session, isHost, colorScheme, minHeight: 140),
                              if (showAdvancedTeams) ...[
                                const SizedBox(height: 16),
                                _buildTeamZone(3, session, isHost, colorScheme, minHeight: 140),
                                const SizedBox(height: 16),
                                _buildTeamZone(4, session, isHost, colorScheme, minHeight: 140),
                              ],
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Controls
            _buildFooterControls(context, transport, session, isHost, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileQRHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrImageView(
            data: _connectionString!,
            version: QrVersions.auto,
            size: 80.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SCAN TO JOIN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 2, fontSize: 12)),
                Text(_connectionString!, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace')),
                const Text('Invite friends to join the arena locally.', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopQRBadge(ColorScheme colorScheme) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: _connectionString!,
            version: QrVersions.auto,
            size: 160.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
          const SizedBox(height: 16),
          const Text('JOIN ARENA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black)),
          const SizedBox(height: 4),
          Text(_connectionString!, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildTeamRow(List<int> teamIds, SessionManager session, bool isHost, ColorScheme colorScheme) {
    return Row(
      children: teamIds.map((id) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: id % 2 == 0 ? 12 : 0, right: id % 2 != 0 ? 12 : 0),
          child: _buildTeamZone(id, session, isHost, colorScheme),
        ),
      )).toList(),
    );
  }

  Widget _buildStatusHeader(ColorScheme colorScheme, SessionManager session, bool isHost) {
    final assignedCount = session.players.values.where((p) => p.teamId > 0).length;
    final readyCount = session.players.values.where((p) => p.teamId > 0 && p.isReady).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusMetric('PLAYERS', '${session.players.length}'),
          Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
          _buildStatusMetric('ASSIGNED', '$assignedCount'),
          Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
          _buildStatusMetric('READY', '$readyCount/$assignedCount', color: readyCount == assignedCount && assignedCount > 0 ? Colors.green : null),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
      ],
    );
  }

  Widget _buildPlayerPool(SessionManager session, bool isHost, ColorScheme colorScheme) {
    final unassigned = session.players.entries.where((e) => e.value.teamId == 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UNASSIGNED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        Expanded(
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => isHost,
            onAcceptWithDetails: (details) {
               _assignTeam(details.data, 0);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: candidateData.isNotEmpty ? colorScheme.primary : Colors.transparent, width: 2),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unassigned.length,
                  itemBuilder: (context, index) {
                    final player = unassigned[index];
                    return _DraggablePlayer(id: player.key, data: player.value, isHost: isHost);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamZone(int teamId, SessionManager session, bool isHost, ColorScheme colorScheme, {double? minHeight}) {
    final teamPlayers = session.players.entries.where((e) => e.value.teamId == teamId).toList();
    final teamColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    final color = teamColors[teamId - 1];
    final teamName = session.teamNames[teamId] ?? 'Team $teamId';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isHost ? () => _showRenameDialog(teamId, teamName) : null,
          child: Row(
            children: [
              Text(teamName.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: color)),
              if (isHost) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.edit_rounded, size: 12, color: color.withValues(alpha: 0.5))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight ?? 0),
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => isHost,
            onAcceptWithDetails: (details) {
              _assignTeam(details.data, teamId);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: candidateData.isNotEmpty ? color : color.withValues(alpha: 0.1), width: 2),
                ),
                child: teamPlayers.isEmpty 
                  ? Container(
                      height: minHeight ?? 100, 
                      alignment: Alignment.center,
                      child: Icon(Icons.add_circle_outline_rounded, color: color.withValues(alpha: 0.2), size: 32),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: teamPlayers.length,
                      itemBuilder: (context, index) {
                        final player = teamPlayers[index];
                        return _DraggablePlayer(id: player.key, data: player.value, isHost: isHost, teamColor: color);
                      },
                    ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRenameDialog(int teamId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RENAME TEAM', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter team name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(transportProvider).sendEvent(GameEvent(
                  type: GameEventType.teamRename,
                  payload: {'teamId': teamId, 'name': controller.text.trim()},
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('RENAME', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterControls(BuildContext context, IGameTransport transport, SessionManager session, bool isHost, ColorScheme colorScheme) {
    final myId = transport.myId;
    final myData = session.players[myId];
    final isReady = myData?.isReady ?? false;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (isHost) ...[
            IconButton(
              onPressed: () => _randomizeTeams(session),
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: 'Randomize Teams',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // 'Ready' button now available for everyone (even unassigned)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _toggleReady(!isReady),
              icon: Icon(isReady ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
              label: Text(isReady ? 'READY' : 'MARK READY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady ? Colors.green : colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),

          if (isHost) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: session.allAssignedReady ? _startMatch : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('START MATCH'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _randomizeTeams(SessionManager session) {
    final unassigned = session.players.entries.where((e) => e.value.teamId == 0).map((e) => e.key).toList();
    if (unassigned.isEmpty) return;
    
    unassigned.shuffle();
    final teamCount = session.players.length > 3 ? 4 : 2;
    
    for (int i = 0; i < unassigned.length; i++) {
       _assignTeam(unassigned[i], (i % teamCount) + 1);
    }
  }

  void _assignTeam(String playerId, int teamId) {
    ref.read(transportProvider).sendEvent(GameEvent(
      type: GameEventType.teamAssignment,
      payload: {'playerId': playerId, 'teamId': teamId},
    ));
  }

  void _toggleReady(bool ready) {
    ref.read(transportProvider).sendEvent(GameEvent(
      type: GameEventType.playerReady,
      payload: {'ready': ready},
    ));
  }

  void _startMatch() async {
    final transport = ref.read(transportProvider);
    final match = ref.read(matchProvider).value;
    final round = ref.read(roundProvider);
    final session = ref.read(sessionProvider);

    if (match == null) return;

    // 1. Pre-generate the entire match
    // Note: In Host mode, MatchManager usually comes from MatchSetupScreen
    // but we ensure it's generated here just in case.
    match.generateMatch();

    final roundData = match.currentRoundData;
    if (roundData == null) return;

    // 2. Load first round locally
    round.startRound(data: roundData);
    session.resetRoundData();

    // 3. Broadcast start with full payload
    await transport.sendEvent(GameEvent(
      type: GameEventType.hostStartedMatch,
      payload: {
        'targets': roundData.targets,
        'target': roundData.targets.first,
        'numbers': roundData.numbers,
        'difficulty': 1, // Simplified
        'config': roundData.config.title,
        'jeopardy': roundData.jeopardy?.index,
        'lockedOperator': roundData.lockedOperator,
        'totalRounds': match.totalRounds,
        'gameMode': match.gameMode.index,
        'currentRound': match.currentRound,
      },
    ));
  }
}

class _DraggablePlayer extends StatelessWidget {
  final String id;
  final PlayerSessionData data;
  final bool isHost;
  final Color? teamColor;

  const _DraggablePlayer({required this.id, required this.data, required this.isHost, this.teamColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.isReady ? Colors.green : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: (teamColor ?? Colors.blue).withValues(alpha: 0.1),
            child: Text(data.name[0].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: teamColor ?? Colors.blue)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(data.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (data.isReady) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
        ],
      ),
    );

    if (!isHost) return content;

    return Draggable<String>(
      data: id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 200, child: content),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: content),
      child: content,
    );
  }
}
