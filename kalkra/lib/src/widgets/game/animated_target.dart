import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

class AnimatedTarget extends StatelessWidget {
  final List<int> targets;
  final bool isHighStakes;
  final AnimationController entrance;
  final bool isDesktop;
  final MatchManager? match;
  const AnimatedTarget({
    super.key,
    required this.targets,
    required this.isHighStakes,
    required this.entrance,
    this.isDesktop = false,
    this.match,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDual = targets.length > 1;
    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: entrance, curve: Curves.easeOutBack)),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isHighStakes
                ? Colors.red.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(isDesktop ? 80 : 56),
            ),
            boxShadow: [
              BoxShadow(
                color: isHighStakes
                    ? Colors.red.withValues(alpha: 0.2)
                    : colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isHighStakes
                        ? 'DOUBLE OR NOTHING'
                        : (isDual ? 'TWO TARGETS' : 'TARGET'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      color: isHighStakes
                          ? Colors.red
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                      fontSize: isDesktop ? 14 : 10,
                    ),
                  ),
                  if (isDual)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTargetText(
                            targets[0],
                            theme,
                            colorScheme.primary,
                          ),
                          const SizedBox(width: 40),
                          _buildTargetText(
                            targets[1],
                            theme,
                            colorScheme.secondary,
                          ),
                        ],
                      ),
                    )
                  else
                    _buildTargetText(
                      targets.isNotEmpty ? targets.first : 0,
                      theme,
                      isHighStakes ? Colors.redAccent : colorScheme.primary,
                    ),
                ],
              ),
              if (match?.gameMode == GameMode.endless)
                Positioned(
                  top: 24,
                  left: 24,
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          i < (match?.lives ?? 0)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 28,
                          color: i < (match?.lives ?? 0)
                              ? Colors.redAccent
                              : colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetText(int val, ThemeData theme, Color color) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      '$val',
      style: theme.textTheme.displayLarge?.copyWith(
        color: color,
        fontSize: isDesktop ? 120 : 110,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
