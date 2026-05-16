import 'package:flutter/material.dart';

class NumberTile extends StatelessWidget {
  final int value;
  final bool isUsed;
  final bool isFocused;
  final VoidCallback onTap;
  final bool small;
  const NumberTile({
    super.key,
    required this.value,
    required this.isUsed,
    required this.isFocused,
    required this.onTap,
    this.small = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = small ? 72.0 : 88.0;
    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isUsed
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(small ? 24 : 32),
          border: isFocused
              ? Border.all(color: colorScheme.primary, width: 4)
              : null,
          boxShadow: [
            BoxShadow(
              color: isUsed
                  ? Colors.transparent
                  : colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: isUsed ? 0 : 25,
              offset: isUsed ? Offset.zero : const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: isUsed
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.2)
                : colorScheme.onPrimaryContainer,
            fontSize: small ? 24 : 32,
          ),
        ),
      ),
    );
  }
}
