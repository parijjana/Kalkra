import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../screens/main_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/account_screen.dart';
import '../screens/achievements_screen.dart';

class TopNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final String activeId;
  final bool showMenu;
  const TopNavBar({super.key, required this.activeId, this.showMenu = true});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final careerAsync = ref.watch(careerProvider);

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Menu Toggle
          if (showMenu) ...[
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 20),
          ] else
            const SizedBox(width: 20),

          // Logo/Brand
          Text(
            'KALKRA',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 4,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 80),

          // Navigation Tabs
          _NavTab(
            label: 'DASHBOARD',
            id: 'MainScreen',
            activeId: activeId,
            onTap: () => _navTo(context, const MainScreen()),
          ),
          _NavTab(
            label: 'ANALYTICS',
            id: 'StatsScreen',
            activeId: activeId,
            onTap: () => _navTo(context, const StatsScreen()),
          ),
          _NavTab(
            label: 'ACHIEVEMENTS',
            id: 'AchievementsScreen',
            activeId: activeId,
            onTap: () => _navTo(context, const AchievementsScreen()),
          ),
          _NavTab(
            label: 'ACCOUNT',
            id: 'AccountScreen',
            activeId: activeId,
            onTap: () => _navTo(context, const AccountScreen()),
          ),

          const Spacer(),

          // Quick Profile Info
          careerAsync.when(
            loading: () => const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (err, stack) =>
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
            data: (career) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      career.playerName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  void _navTo(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => screen,
        transitionDuration: Duration.zero, // Instant switch for tab feel
      ),
      (route) => false,
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final String id;
  final String activeId;
  final VoidCallback onTap;

  const _NavTab({
    required this.label,
    required this.id,
    required this.activeId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = id == activeId;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 2,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
