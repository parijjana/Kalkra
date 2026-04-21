import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_interface/transport_interface.dart';
import '../providers/game_providers.dart';
import '../screens/main_screen.dart';

class GlobalDrawer extends ConsumerWidget {
  const GlobalDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final transport = ref.watch(transportProvider);
    final match = ref.read(matchProvider).value;
    final isSolo = transport is NullTransport;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Center(
              child: Text(
                'KALKRA MENU',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard_rounded, color: colorScheme.primary),
            title: const Text('MAIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: isSolo ? const Text('Pauses current practice') : null,
            onTap: () {
              if (isSolo && match != null) {
                ref.read(isPausedProvider.notifier).setPaused(true);
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
            title: const Text('END MATCH', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            subtitle: const Text('Discard current progress'),
            onTap: () => _confirmEndMatch(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmEndMatch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('END MATCH?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Your current progress will be lost. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(isPausedProvider.notifier).setPaused(false);
              ref.read(matchProvider).value = null;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
            child: const Text('END GAME', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
