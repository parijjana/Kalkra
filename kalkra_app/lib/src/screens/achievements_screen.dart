import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/global_drawer.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('AchievementsScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final careerAsync = ref.watch(careerProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return careerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Vault Error: $err'))),
      data: (career) => Scaffold(
        backgroundColor: colorScheme.surface,
        drawer: const GlobalDrawer(),
        appBar: isDesktop ? const TopNavBar(activeId: 'AchievementsScreen') : AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/app_icon.svg',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 12),
              const Text('ACHIEVEMENTS'),
            ],
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        body: VectorBackground(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(career, theme, colorScheme),
                      const SizedBox(height: 48),
                      _buildAchievementsGrid(context, career, isDesktop),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CareerManager career, ThemeData theme, ColorScheme colorScheme) {
    final unlockedCount = career.unlockedAchievements.length;
    final totalCount = AchievementRegistry.all.length;
    final progress = unlockedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PROGRESS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 12, color: colorScheme.primary)),
                const SizedBox(height: 12),
                Text('$unlockedCount / $totalCount UNLOCKED', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: colorScheme.primary.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Icon(Icons.emoji_events_rounded, size: 80, color: colorScheme.primary.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context, CareerManager career, bool isDesktop) {
    final unlockedIds = career.unlockedAchievements;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isDesktop ? 3.0 : 4.0,
      ),
      itemCount: AchievementRegistry.all.length,
      itemBuilder: (context, index) {
        final achievement = AchievementRegistry.all[index];
        final isUnlocked = unlockedIds.contains(achievement.id);
        
        if (achievement.isHidden && !isUnlocked) {
          return const _AchievementTile(
            title: '???',
            description: 'Secret Achievement',
            isUnlocked: false,
            category: AchievementCategory.speed, 
          );
        }

        return _AchievementTile(
          title: achievement.title,
          description: achievement.description,
          isUnlocked: isUnlocked,
          category: achievement.category,
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String description;
  final bool isUnlocked;
  final AchievementCategory category;

  const _AchievementTile({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = isUnlocked ? _getCategoryColor(category) : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? baseColor.withValues(alpha: 0.1) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnlocked ? baseColor.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? baseColor : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
              color: isUnlocked ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isUnlocked ? colorScheme.onSurface : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.speed: return Colors.orange;
      case AchievementCategory.precision: return Colors.blue;
      case AchievementCategory.endurance: return Colors.redAccent;
      case AchievementCategory.multiplayer: return Colors.purple;
      case AchievementCategory.quirky: return Colors.amber;
      default: return Colors.blueGrey;
    }
  }
}
