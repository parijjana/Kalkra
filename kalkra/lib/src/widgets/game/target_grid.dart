import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact 2x2 or 3x3 grid of targets.
class TargetGrid extends ConsumerWidget {
  final List<int> targets;
  final Function(int) onTargetTap;

  const TargetGrid({
    super.key,
    required this.targets,
    required this.onTargetTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = targets.length;
    final int crossAxisCount = count <= 4 ? 2 : 3;

    // Adjust aspect ratio to ensure it fits in the viewport without scrolling
    final double childAspect = count <= 4 ? 2.0 : 1.6;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: crossAxisCount == 2 ? 300 : 450),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspect,
          ),
          itemCount: count.clamp(0, 9),
          itemBuilder: (context, index) {
            final val = targets[index];
            return _TargetTile(value: val, onTap: () => onTargetTap(val));
          },
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  final int value;
  final VoidCallback onTap;

  const _TargetTile({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$value',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
