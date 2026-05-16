import 'package:flutter/material.dart';

class ExpressionSection extends StatelessWidget {
  final String currentExpression; final VoidCallback onBackspace; final bool isLarge;
  const ExpressionSection({super.key, required this.currentExpression, required this.onBackspace, this.isLarge = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    return Container(width: isLarge ? 900 : double.infinity, padding: EdgeInsets.symmetric(vertical: isLarge ? 48 : 32, horizontal: 24), margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.1), blurRadius: 60, offset: const Offset(0, 25))]), child: Row(children: [
        Expanded(child: Text(currentExpression.isEmpty ? 'BUILD EXPRESSION' : currentExpression, style: theme.textTheme.headlineMedium?.copyWith(color: currentExpression.isEmpty ? colorScheme.onSurface.withValues(alpha: 0.2) : colorScheme.onSurface, fontWeight: FontWeight.w900, fontFamily: 'monospace', fontSize: isLarge ? 40 : 24), textAlign: TextAlign.center)),
        if (currentExpression.isNotEmpty) IconButton(onPressed: onBackspace, icon: Icon(Icons.backspace_rounded, color: colorScheme.primary, size: isLarge ? 40 : 28)),
    ]));
  }
}
