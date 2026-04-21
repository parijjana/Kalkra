import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:transport_interface/transport_interface.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  bool _isConnecting = false;
  final TextEditingController _ipController = TextEditingController();

  Future<void> _connect(String connectionInfo) async {
    if (_isConnecting) return;
    
    setState(() => _isConnecting = true);
    
    try {
      final clientTransport = LanClientTransport();
      ref.read(transportProvider.notifier).setTransport(clientTransport);
      
      final career = ref.read(careerProvider);
      
      await clientTransport.joinSession(
        playerName: career.playerName,
        connectionInfo: connectionInfo,
        options: {'elo': career.elo},
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to session!')),
        );
        // TODO: Navigate to Lobby or wait for start
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('JoinScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventAsync = ref.watch(gameEventStreamProvider);

    // Listen for game start event
    eventAsync.whenData((event) {
      if (event.type == GameEventType.roundStarted) {
        final List<int> numbers = List<int>.from(event.payload['numbers']);
        final int target = event.payload['target'];
        
        ref.read(roundProvider).startRoundWithData(numbers: numbers, target: target);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('JOIN SESSION'),
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiaryContainer,
      ),
      body: Column(
        children: [
          // Scanner Area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(48),
                border: Border.all(color: colorScheme.tertiary, width: 4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _connect(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                  // Scanner Overlay (Vector Pop)
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.tertiary, width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'ALIGN QR CODE INSIDE BOX',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Manual Entry Area
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
              ),
              child: Column(
                children: [
                  Text(
                    'OR ENTER IP MANUALLY',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: 'ws://192.168.1.5:8080',
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isConnecting ? null : () => _connect(_ipController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.tertiary,
                        foregroundColor: colorScheme.onTertiaryContainer,
                      ),
                      child: _isConnecting
                          ? const CircularProgressIndicator()
                          : const Text(
                              'CONNECT',
                              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
