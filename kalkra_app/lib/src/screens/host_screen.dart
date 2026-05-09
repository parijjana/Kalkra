import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:game_engine/game_engine.dart';
import '../providers/game_providers.dart';
import '../providers/hosted_session_provider.dart';
import '../config/device_util.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'staging_screen.dart';
import 'hosted_history_screen.dart';

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
  bool _isProgressive = false;
  bool _jeopardyEnabled = true;

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
    
    final career = await ref.read(careerProvider.future);
    final sessionManager = ref.read(hostedSessionProvider.notifier);

    await hostTransport.hostSession(
      playerName: career.playerName,
      options: {
        'port': _port,
        'elo': career.elo,
        'isSpectator': true,
        'bannedDeviceIds': sessionManager.getBannedDeviceIds(),
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

  // ... rest of init same

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('HostScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final transport = ref.watch(transportProvider);

    String? secret;
    if (transport is LanHostTransport) {
      secret = transport.lobbySecret;
    }
    
    final connectionString = 'ws://$_ipAddress:$_port${secret != null ? "?secret=$secret" : ""}';
    
    // Difficulty label logic
    String diffLabel = _isProgressive ? 'PROGRESSIVE' : _difficulty.name.toUpperCase();

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
            const Flexible(child: Text('HOST SETUP', overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: colorScheme.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HostedHistoryScreen())),
            icon: const Icon(Icons.history_edu_rounded),
          ),
        ],
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
                  Expanded(child: _RoleButton(label: 'JOIN AS PLAYER', icon: Icons.sports_esports_rounded, isActive: !_isSpectator, onTap: () => setState(() => _isSpectator = false))),
                  const SizedBox(width: 12),
                  Expanded(child: _RoleButton(label: 'REMAIN HOST', icon: Icons.visibility_rounded, isActive: _isSpectator, onTap: () => setState(() => _isSpectator = true))),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // 2. Match Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(32)),
                child: Column(
                  children: [
                    Row(children: [const Icon(Icons.settings_rounded, size: 20), const SizedBox(width: 12), Text('MATCH SETTINGS', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2))]),
                    const SizedBox(height: 24),
                    _SettingRow(label: 'ROUNDS', value: '$_totalRounds', onDecrement: () => setState(() => _totalRounds = (_totalRounds - 1).clamp(1, 20)), onIncrement: () => setState(() => _totalRounds = (_totalRounds + 1).clamp(1, 20))),
                    const Divider(height: 32),
                    _SettingRow(
                      label: 'DIFFICULTY', 
                      value: diffLabel, 
                      onDecrement: () {
                         setState(() {
                           if (_isProgressive) {
                             _isProgressive = false;
                             _difficulty = Difficulty.hard;
                           } else if (_difficulty.index > 0) {
                             _difficulty = Difficulty.values[_difficulty.index - 1];
                           } else {
                             _isProgressive = true;
                           }
                         });
                      }, 
                      onIncrement: () {
                         setState(() {
                           if (_isProgressive) {
                             _isProgressive = false;
                             _difficulty = Difficulty.easy;
                           } else if (_difficulty.index < 2) {
                             _difficulty = Difficulty.values[_difficulty.index + 1];
                           } else {
                             _isProgressive = true;
                           }
                         });
                      }
                    ),
                    const Divider(height: 32),
                    SwitchListTile(title: Text('RANDOM JEOPARDY (30%)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)), value: _jeopardyEnabled, onChanged: (v) => setState(() => _jeopardyEnabled = v), activeThumbColor: colorScheme.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // QR Code Area same...
            Container(margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(48), boxShadow: [BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 12))]), child: Column(children: [
              if (_isHosting) ...[
                QrImageView(data: connectionString, version: QrVersions.auto, size: 240.0, eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: colorScheme.primary), dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: colorScheme.onSurface)),
                const SizedBox(height: 24),
                Text('SCAN TO JOIN', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.primary)),
                const SizedBox(height: 8),
                Text(connectionString, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.4), fontFamily: 'monospace')),
              ] else
                const CircularProgressIndicator(),
            ])),

            const SizedBox(height: 48),

            // Open Lobby Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: _isHosting ? () async {
                    final transport = ref.read(transportProvider);
                    final career = ref.read(careerProvider).value;
                    if (career == null) return;
                    
                    final deviceId = await DeviceIdUtil.getDeviceId();

                    // 1. Update Spectator Role
                    ref.read(isHostOnlyProvider.notifier).setState(_isSpectator);

                    // 2. Add Host to Session if playing
                    if (!_isSpectator) {
                      await transport.sendEvent(GameEvent(type: GameEventType.playerJoined, payload: PlayerInfo(id: 'host', name: career.playerName, isHost: true, currentElo: career.elo, deviceId: deviceId).toJson()));
                    }

                    // 3. Setup Match Manager
                    final match = MatchManager(
                      totalRounds: _totalRounds, 
                      jeopardyEnabled: _jeopardyEnabled, 
                      gameMode: _isProgressive ? GameMode.progressive : GameMode.multiplayer
                    );
                    ref.read(matchProvider).value = match;
                    session.resetScores();
                    session.resetRoundData();

                    // 4. Transition to Staging
                    if (mounted) {
                      Navigator.of(this.context).pushReplacement(MaterialPageRoute(builder: (context) => const StagingScreen()));
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
                  child: Text('OPEN ARENA LOBBY', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
  final String label; final IconData icon; final bool isActive; final VoidCallback onTap;
  const _RoleButton({required this.label, required this.icon, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: isActive ? colorScheme.primary : colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(icon, color: isActive ? Colors.white : colorScheme.onSurfaceVariant), const SizedBox(height: 8), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isActive ? Colors.white : colorScheme.onSurfaceVariant))])));
  }
}

class _SettingRow extends StatelessWidget {
  final String label; final String value; final VoidCallback onDecrement; final VoidCallback onIncrement;
  const _SettingRow({required this.label, required this.value, required this.onDecrement, required this.onIncrement});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove_circle_outline)), Container(width: 80, alignment: Alignment.center, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), IconButton(onPressed: onIncrement, icon: const Icon(Icons.add_circle_outline))]);
  }
}
