import 'package:flutter/material.dart';

class OpButton extends StatelessWidget {
  final String label; final String? shortcut; final VoidCallback onTap; final Color? color; final Color? textColor; final bool isLocked; final double size;
  const OpButton({super.key, required this.label, this.shortcut, required this.onTap, this.color, this.textColor, this.isLocked = false, this.size = 80});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    final btnColor = isLocked ? colorScheme.surfaceContainerHighest : (color ?? colorScheme.primary);
    final isMobile = theme.platform == TargetPlatform.android || theme.platform == TargetPlatform.iOS;
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: isLocked ? [] : [BoxShadow(color: btnColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]), child: Stack(children: [
          ElevatedButton(onPressed: isLocked ? null : onTap, style: ElevatedButton.styleFrom(minimumSize: Size(size, size), backgroundColor: btnColor, disabledBackgroundColor: colorScheme.surfaceContainerHighest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0), child: isLocked ? const Icon(Icons.lock_rounded, color: Colors.grey) : Text(label, style: TextStyle(fontSize: size * 0.5, color: textColor ?? colorScheme.onPrimary, fontWeight: FontWeight.w900))),
          if (shortcut != null && !isLocked && !isMobile) Positioned(top: 4, right: 6, child: Text(shortcut!, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: (textColor ?? colorScheme.onPrimary).withValues(alpha: 0.5)))),
    ]));
  }
}
