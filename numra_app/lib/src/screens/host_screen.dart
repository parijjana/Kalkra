import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:game_engine/game_engine.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';

class HostScreen extends ConsumerStatefulWidget {
  const HostScreen({super.key});

  @override
  ConsumerState<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends ConsumerState<HostScreen> {
  String? _ipAddress;
  int _port = 8080;
  bool _isHosting = false;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventAsync = ref.watch(gameEventStreamProvider);
    final session = ref.watch(sessionProvider);

    // Update session manager when players join or submit
    eventAsync.whenData((event) {
      if (event.type == GameEventType.playerJoined) {
        final player = PlayerInfo.fromJson(event.payload);
        session.addPlayer(player.id, player.name, elo: player.currentElo);
      } else if (event.type == GameEventType.submissionReceived) {
        final playerId = event.payload['playerId'];
        final expression = event.payload['expression'];
        final round = ref.read(roundProvider);
        final points = round.calculatePoints(expression);
        session.recordSubmission(playerId, expression, points);
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
                      trailing: index == 0 // Assuming first is host for now
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
                  onPressed: players.isNotEmpty ? () async {
                    // Initialize match and first round
                    final match = MatchManager(totalRounds: 5);
                    ref.read(matchProvider).value = match;
                    
                    final round = ref.read(roundProvider);
                    round.startRound(difficulty: match.currentDifficulty);
                    session.resetRoundData();
                    
                    // Broadcast to clients
                    final transport = ref.read(transportProvider);
                    await transport.sendEvent(GameEvent(
                      type: GameEventType.roundStarted,
                      payload: {
                        'target': round.target,
                        'numbers': round.numbers,
                        'difficulty': match.currentDifficulty.index,
                      },
                    ));

                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const GameScreen()),
                      );
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
