import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String roundText;
  final int myScore;
  final int secondsLeft;
  final VoidCallback onExit;
  final VoidCallback onClear;
  const GameHeader({
    super.key,
    required this.roundText,
    required this.myScore,
    required this.secondsLeft,
    required this.onExit,
    required this.onClear,
  });
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
      foregroundColor: colorScheme.onPrimary,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$roundText • SCORE: $myScore',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          Text(
            'TIME: $secondsLeft',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(onPressed: onExit, icon: const Icon(Icons.logout_rounded)),
        IconButton(onPressed: onClear, icon: const Icon(Icons.refresh_rounded)),
      ],
    );
  }
}
