import 'package:flutter/material.dart';
import 'op_button.dart';

class ControlsSection extends StatelessWidget {
  final Function(String) onOperatorTap;
  final VoidCallback onSubmit;
  final String? lockedOperator;
  final bool isLarge;
  const ControlsSection({
    super.key,
    required this.onOperatorTap,
    required this.onSubmit,
    this.lockedOperator,
    this.isLarge = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = isLarge ? 80.0 : 44.0;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isLarge ? 950 : double.infinity),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OpButton(
                  label: '+',
                  shortcut: 'H',
                  onTap: () => onOperatorTap('+'),
                  isLocked: lockedOperator == '+',
                  size: size,
                ),
                OpButton(
                  label: '-',
                  shortcut: 'J',
                  onTap: () => onOperatorTap('-'),
                  isLocked: lockedOperator == '-',
                  size: size,
                ),
                OpButton(
                  label: '×',
                  shortcut: 'K',
                  onTap: () => onOperatorTap('*'),
                  isLocked: lockedOperator == '*',
                  size: size,
                ),
                OpButton(
                  label: '÷',
                  shortcut: 'L',
                  onTap: () => onOperatorTap('/'),
                  isLocked: lockedOperator == '/',
                  size: size,
                ),
                OpButton(
                  label: '(',
                  shortcut: 'N',
                  onTap: () => onOperatorTap('('),
                  color: colorScheme.surfaceContainerHighest,
                  textColor: colorScheme.onSurfaceVariant,
                  size: size,
                ),
                OpButton(
                  label: ')',
                  shortcut: 'M',
                  onTap: () => onOperatorTap(')'),
                  color: colorScheme.surfaceContainerHighest,
                  textColor: colorScheme.onSurfaceVariant,
                  size: size,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: isLarge ? 80 : 64,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withValues(alpha: 0.4),
                      blurRadius: 35,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Text(
                    'SUBMIT',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      fontSize: isLarge ? 24 : 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
