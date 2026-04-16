import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';
import 'host_screen.dart';
import 'join_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider).value;
    final career = ref.watch(careerProvider).value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Linear Gradient & Profile Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(48),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KALKRA',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontSize: 64,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MASTER THE NUMBERS',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.tertiaryContainer,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: colorScheme.tertiaryContainer,
                            child: const Icon(Icons.person_rounded, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Compact Elo Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${settings.playerName} • ${career.elo} ELO',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Mode Selection Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'THE ARENA',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 16),

            _ModeCard(
              title: 'SOLO PRACTICE',
              description: 'Hone your mental math skills.',
              icon: Icons.person_rounded,
              color: colorScheme.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
            ),

            _ModeCard(
              title: 'MULTIPLAYER',
              description: 'Host or join a local session.',
              icon: Icons.groups_rounded,
              color: colorScheme.secondary,
              onTap: () {
                _showMultiplayerDialog(context);
              },
            ),

            const SizedBox(height: 32),

            // Career Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'YOUR CAREER',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 16),

            _ModeCard(
              title: 'VIEW STATS',
              description: 'Check your speed and rankings.',
              icon: Icons.bar_chart_rounded,
              color: colorScheme.tertiary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              },
            ),

            const SizedBox(height: 40),
            
            // Settings Footer
            Center(
              child: IconButton.filledTonal(
                onPressed: () {
                  // TODO: Implement Settings Screen
                },
                icon: const Icon(Icons.settings_rounded),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showMultiplayerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(48))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('MULTIPLAYER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'HOST',
                    icon: Icons.qr_code_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HostScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DialogButton(
                    label: 'JOIN',
                    icon: Icons.sensors_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const JoinScreen()));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({required this.title, required this.description, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(48),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(48),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withOpacity(0.2), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DialogButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 32),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}
