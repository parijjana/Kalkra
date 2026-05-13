import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:nsd/nsd.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/global_drawer.dart';
import '../config/device_util.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'staging_screen.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _manualController = TextEditingController();
  bool _isConnecting = false;
  Discovery? _discovery;
  final List<Service> _discoveredServices = [];

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    _discovery = await startDiscovery('_kalkra._tcp');
    _discovery?.addListener(() {
      if (mounted) {
        setState(() {
          _discoveredServices.clear();
          _discoveredServices.addAll(_discovery!.services);
        });
      }
    });
  }

  Future<void> _stopDiscovery() async {
    if (_discovery != null) await stopDiscovery(_discovery!);
  }

  @override
  void dispose() {
    _stopDiscovery();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _join(String connectionInfo) async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);

    try {
      final clientTransport = LanClientTransport();
      final career = await ref.read(careerProvider.future);
      final deviceId = await DeviceIdUtil.getDeviceId();

      await clientTransport.joinSession(
        playerName: career.playerName,
        connectionInfo: connectionInfo,
        options: {'elo': career.elo, 'deviceId': deviceId},
      );

      ref.read(transportProvider.notifier).setTransport(clientTransport);
      ref.read(isHostOnlyProvider.notifier).setState(false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => StagingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  String _getTxtValue(Service service, String key) {
    final value = service.txt?[key];
    if (value == null) return '';
    return utf8.decode(value);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('JoinScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: isDesktop
          ? const TopNavBar(activeId: 'JoinScreen')
          : AppBar(
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
                    child: Text('JOIN ARENA', overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              backgroundColor: colorScheme.tertiary,
              foregroundColor: Colors.white,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
      body: VectorBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'LOCAL GAMES'),
              const SizedBox(height: 16),
              if (_discoveredServices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'SCANNING WI-FI...',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _discoveredServices.length,
                  itemBuilder: (context, index) {
                    final service = _discoveredServices[index];
                    final hostName = _getTxtValue(service, 'hostName');
                    final elo = _getTxtValue(service, 'elo');
                    final ip = service.addresses?.first.address ?? '...';
                    final port = service.port;
                    final connectionUri = 'ws://$ip:$port';

                    return _HostCard(
                      name: hostName.isEmpty ? 'Unknown Host' : hostName,
                      elo: elo.isEmpty ? '????' : elo,
                      onTap: () => _join(connectionUri),
                    );
                  },
                ),

              const SizedBox(height: 48),
              _SectionHeader(title: 'SCAN QR CODE'),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: SizedBox(
                  height: 300,
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _join(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 48),
              _SectionHeader(title: 'MANUAL ENTRY'),
              const SizedBox(height: 16),
              TextField(
                controller: _manualController,
                decoration: InputDecoration(
                  hintText: 'ws://192.168.1.5:8080',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: () => _join(_manualController.text.trim()),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  final String name;
  final String elo;
  final VoidCallback onTap;

  const _HostCard({required this.name, required this.elo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.tertiary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'AVAILABLE ARENA',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'JOIN',
                  style: TextStyle(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
