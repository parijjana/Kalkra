import 'package:flutter/material.dart';

/// A CustomPainter that renders a 'Vector Pop' pattern with overlapping
/// triangles, circles, and mathematical symbols.
class VectorPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final double opacity;

  VectorPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    this.opacity = 0.05,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw overlapping shapes for texture
    _drawTriangle(canvas, size, paint, primaryColor.withValues(alpha: opacity), const Offset(0.2, 0.2), 300);
    _drawCircle(canvas, size, paint, secondaryColor.withValues(alpha: opacity), const Offset(0.8, 0.3), 200);
    _drawTriangle(canvas, size, paint, tertiaryColor.withValues(alpha: opacity), const Offset(0.5, 0.8), 400);
    
    // Draw some symbols
    _drawSymbol(canvas, size, '+', primaryColor.withValues(alpha: opacity * 2), const Offset(0.1, 0.7), 80);
    _drawSymbol(canvas, size, '÷', secondaryColor.withValues(alpha: opacity * 2), const Offset(0.9, 0.1), 100);
    _drawSymbol(canvas, size, '×', tertiaryColor.withValues(alpha: opacity * 2), const Offset(0.4, 0.4), 120);
  }

  void _drawTriangle(Canvas canvas, Size size, Paint paint, Color color, Offset relativePos, double side) {
    paint.color = color;
    final path = Path();
    final center = Offset(size.width * relativePos.dx, size.height * relativePos.dy);
    path.moveTo(center.dx, center.dy - side / 2);
    path.lineTo(center.dx - side / 2, center.dy + side / 2);
    path.lineTo(center.dx + side / 2, center.dy + side / 2);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCircle(Canvas canvas, Size size, Paint paint, Color color, Offset relativePos, double radius) {
    paint.color = color;
    canvas.drawCircle(Offset(size.width * relativePos.dx, size.height * relativePos.dy), radius, paint);
  }

  void _drawSymbol(Canvas canvas, Size size, String symbol, Color color, Offset relativePos, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * relativePos.dx, size.height * relativePos.dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VectorBackground extends StatelessWidget {
  final Widget child;
  const VectorBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: VectorPatternPainter(
              primaryColor: colorScheme.primary,
              secondaryColor: colorScheme.secondary,
              tertiaryColor: colorScheme.tertiary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
