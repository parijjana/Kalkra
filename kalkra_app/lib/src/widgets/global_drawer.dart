import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/game_providers.dart';
import '../screens/main_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/account_screen.dart';
import '../screens/host_screen.dart';
import '../screens/join_screen.dart';
import '../screens/match_setup_screen.dart';
import '../screens/hosted_history_screen.dart';
import '../screens/session_recap_screen.dart';
import '../screens/game_screen.dart';

class GlobalDrawer extends ConsumerWidget {
  const GlobalDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transport = ref.watch(transportProvider);
    final isSolo = transport is NullTransport;
    final careerAsync = ref.watch(careerProvider);

    return Drawer(
      backgroundColor: colorScheme.surface,
      width: 320,
      child: careerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Vault Error: $err')),
        data: (career) => Column(
          children: [
            // Branding Header
            _buildDrawerHeader(context, career, colorScheme),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildDrawerSection(context, 'THE ARENA', [
                    _DrawerItem(
                      icon: Icons.psychology_rounded,
                      label: 'SOLO MISSION',
                      subtitle: ref.watch(isPausedProvider) ? 'RESUME SESSION' : 'Sharpen your speed',
                      onTap: () {
                        if (ref.read(isPausedProvider)) {
                          _navTo(context, const GameScreen());
                        } else {
                          _navTo(context, const MatchSetupScreen(mode: MatchSetupMode.solo));
                        }
                      },
                      color: ref.watch(isPausedProvider) ? Colors.orangeAccent : colorScheme.primary,
                    ),
                    _DrawerItem(
                      icon: Icons.sensors_rounded,
                      label: 'HOST ARENA',
                      subtitle: 'Local multiplayer hub',
                      onTap: () => _navTo(context, const HostScreen()),
                      color: colorScheme.secondary,
                    ),
                    _DrawerItem(
                      icon: Icons.bolt_rounded,
                      label: 'JOIN BATTLE',
                      subtitle: 'Enter active match',
                      onTap: () => _navTo(context, const JoinScreen()),
                      color: colorScheme.tertiary,
                    ),
                  ]),

                  const Divider(height: 40, indent: 24, endIndent: 24),

                  _buildDrawerSection(context, 'METRICS & PROGRESS', [
                    _DrawerItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'ANALYTICS',
                      onTap: () => _navTo(context, const StatsScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'ACHIEVEMENTS',
                      onTap: () => _navTo(context, const AchievementsScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.history_rounded,
                      label: 'HOST HISTORY',
                      onTap: () => _navTo(context, const HostedHistoryScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.auto_graph_rounded,
                      label: 'SESSION RECAP',
                      onTap: () => _navTo(context, const SessionRecapScreen()),
                    ),
                  ]),

                  const Divider(height: 40, indent: 24, endIndent: 24),

                  _buildDrawerSection(context, 'PREFERENCES', [
                    _DrawerItem(
                      icon: Icons.manage_accounts_rounded,
                      label: 'ACCOUNT',
                      onTap: () => _navTo(context, const AccountScreen()),
                    ),
                  ]),

                  if (!isSolo) ...[
                    const Divider(height: 40, indent: 24, endIndent: 24),
                    _buildDrawerSection(context, 'MULTIPLAYER CONTROL', [
                      _DrawerItem(
                        icon: Icons.logout_rounded,
                        label: transport is LanHostTransport ? 'END SESSION' : 'RESIGN MATCH',
                        onTap: () => _resign(context, ref, transport is LanHostTransport),
                        color: Colors.redAccent,
                      ),
                    ]),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  void _resign(BuildContext context, WidgetRef ref, bool isHost) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHost ? 'TERMINATE SESSION?' : 'RESIGN MATCH?'),
        content: Text(isHost ? 'This will kick all players and close the lobby.' : 'You will be removed from the arena.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final transport = ref.read(transportProvider);
              transport.disconnect();
              ref.read(transportProvider.notifier).setTransport(NullTransport());
              ref.read(matchStatusProvider.notifier).setStatus(MatchStatus.lobby);
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
            }, 
            child: Text(isHost ? 'TERMINATE' : 'RESIGN', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, dynamic career, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/app_icon.svg',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KALKRA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 4,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'V1.1.0-REACTIVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      letterSpacing: 2,
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primary,
                child: Text(career.playerName[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(career.playerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({required this.icon, required this.label, this.subtitle, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemColor = color ?? colorScheme.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: itemColor)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: itemColor.withValues(alpha: 0.4))) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
