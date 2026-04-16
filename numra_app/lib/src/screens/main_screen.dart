import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';
import 'host_screen.dart';
import 'join_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'package:transport_interface/transport_interface.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final career = ref.watch(careerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Vibrant Gradient & Profile Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(56),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
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
                                fontSize: 72,
                                height: 0.9,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MASTER THE NUMBERS',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ProfileBadge(onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Compact Elo Badge with Glow
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${career.playerName} • ${career.elo} ELO',
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Mode Selection Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'THE ARENA',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _ModeCard(
              title: 'SOLO PRACTICE',
              description: 'Hone your mental math skills.',
              icon: Icons.person_rounded,
              color: colorScheme.primary,
              onTap: () async {
                final transport = NullTransport();
                ref.read(transportProvider.notifier).setTransport(transport);
                await transport.hostSession(playerName: career.playerName, options: {'elo': career.elo});
                
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const GameScreen()),
                  );
                }
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
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 24),

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

            const SizedBox(height: 60),
            
            // Settings Footer
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: IconButton.filledTonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings_rounded),
                  padding: const EdgeInsets.all(20),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _showMultiplayerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(56)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'MULTIPLAYER', 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 4),
            ),
            const SizedBox(height: 40),
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
                const SizedBox(width: 24),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
        ),
        child: CircleAvatar(
          radius: 32,
          backgroundColor: colorScheme.tertiaryContainer,
          child: Icon(Icons.person_rounded, color: colorScheme.onTertiaryContainer, size: 32),
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
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            // Layered "Vector Pop" Shadows
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(40),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title, 
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900, 
                            color: colorScheme.onSurface,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description, 
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withValues(alpha: 0.15), size: 18),
                ],
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 40),
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
