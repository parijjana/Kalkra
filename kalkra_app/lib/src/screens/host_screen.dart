import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:game_engine/game_engine.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';
import 'spectator_screen.dart';

class HostScreen extends ConsumerStatefulWidget {
  const HostScreen({super.key});

  @override
  ConsumerState<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends ConsumerState<HostScreen> {
  String? _ipAddress;
  int _port = 8080;
  bool _isHosting = false;
  bool _isSpectator = false;
  int _totalRounds = 5;
  Difficulty _difficulty = Difficulty.easy;
  bool _nextRoundJeopardy = false;

  @override
  void initState() {
    super.initState();
    _setupHost();
  }

  Future<void> _setupHost() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP() ?? '127.0.0.1';
    
    final hostTransport = LanHostTransport();
    ref.read(transportProvider.notifier).setTransport(hostTransport);
    
    final career = ref.read(careerProvider);

    await hostTransport.hostSession(
      playerName: career.playerName,
      options: {
        'port': _port,
        'elo': career.elo,
        'isSpectator': true, // Host stays in spectator mode during lobby
      },
    );

    if (mounted) {
      setState(() {
        _ipAddress = ip;
        _port = hostTransport.port;
        _isHosting = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('HostScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventAsync = ref.watch(gameEventStreamProvider);
    final session = ref.watch(sessionProvider);

    // Update session manager when players join or submit
    eventAsync.whenData((event) {
      if (event.type == GameEventType.playerJoined) {
        final player = PlayerInfo.fromJson(event.payload);
        session.addPlayer(player.id, player.name, elo: player.currentElo, isHost: player.isHost);
      } else if (event.type == GameEventType.submissionReceived) {
        final playerId = event.payload['playerId'];
        final expression = event.payload['expression'];
        session.recordSubmission(playerId, expression, 0);
      }
    });

    final players = session.players.values.toList();
    final connectionString = 'ws://$_ipAddress:$_port';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('HOST SESSION'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // 1. Role Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _RoleButton(
                      label: 'JOIN AS PLAYER',
                      icon: Icons.sports_esports_rounded,
                      isActive: !_isSpectator,
                      onTap: () => setState(() => _isSpectator = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleButton(
                      label: 'REMAIN HOST',
                      icon: Icons.visibility_rounded,
                      isActive: _isSpectator,
                      onTap: () => setState(() => _isSpectator = true),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // 2. Match Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_rounded, size: 20),
                        const SizedBox(width: 12),
                        Text('MATCH SETTINGS', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SettingRow(
                      label: 'ROUNDS',
                      value: '$_totalRounds',
                      onDecrement: () => setState(() => _totalRounds = (_totalRounds - 1).clamp(1, 20)),
                      onIncrement: () => setState(() => _totalRounds = (_totalRounds + 1).clamp(1, 20)),
                    ),
                    const Divider(height: 32),
                    _SettingRow(
                      label: 'DIFFICULTY',
                      value: _difficulty.name.toUpperCase(),
                      onDecrement: () => setState(() => _difficulty = Difficulty.values[(_difficulty.index - 1).clamp(0, 2)]),
                      onIncrement: () => setState(() => _difficulty = Difficulty.values[(_difficulty.index + 1).clamp(0, 2)]),
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: Text('INITIAL JEOPARDY', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      value: _nextRoundJeopardy,
                      onChanged: (v) => setState(() => _nextRoundJeopardy = v),
                      activeThumbColor: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // QR Code Area
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_isHosting) ...[
                    QrImageView(
                      data: connectionString,
                      version: QrVersions.auto,
                      size: 240.0,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: colorScheme.primary,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SCAN TO JOIN',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      connectionString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ] else
                    const CircularProgressIndicator(),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Player List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'PLAYERS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${players.length}',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Player List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(player.name[0].toUpperCase()),
                      ),
                      title: Text(
                        player.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${player.currentElo} ELO'),
                      trailing: player.isHost
                          ? const Icon(Icons.star_rounded, color: Colors.amber)
                          : const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // Start Match Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: players.isNotEmpty || !_isSpectator ? () async {
                    final transport = ref.read(transportProvider);
                    final career = ref.read(careerProvider);

                    if (!_isSpectator) {
                      await transport.sendEvent(GameEvent(
                        type: GameEventType.playerJoined,
                        payload: PlayerInfo(id: 'host', name: career.playerName, isHost: true, currentElo: career.elo).toJson(),
                      ));
                    }

                    final match = MatchManager(totalRounds: _totalRounds, jeopardyEnabled: _nextRoundJeopardy);
                    ref.read(matchProvider).value = match;
                    
                    final round = ref.read(roundProvider);
                    round.startRound(difficulty: _difficulty);
                    session.resetRoundData();
                    
                    await transport.sendEvent(GameEvent(
                      type: GameEventType.roundStarted,
                      payload: {
                        'target': round.target,
                        'numbers': round.numbers,
                        'difficulty': _difficulty.index,
                        'isSpectator': _isSpectator,
                      },
                    ));

                    if (mounted) {
                      if (_isSpectator) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const SpectatorScreen()),
                        );
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const GameScreen()),
                        );
                      }
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'START MATCH',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _SettingRow({required this.label, required this.value, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove_circle_outline)),
        Container(
          width: 80,
          alignment: Alignment.center,
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        IconButton(onPressed: onIncrement, icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}
