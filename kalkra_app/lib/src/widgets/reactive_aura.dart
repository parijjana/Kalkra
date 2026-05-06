import 'dart:math';
import 'package:flutter/material.dart';

enum AuraOperator { plus, minus, times, divide, none }

class ReactiveAura extends StatefulWidget {
  final double proximity;
  final double timerProgress;
  final AuraOperator operator;
  final Color baseColor;

  const ReactiveAura({
    super.key,
    required this.proximity,
    required this.timerProgress,
    this.operator = AuraOperator.none,
    required this.baseColor,
  });

  @override
  State<ReactiveAura> createState() => _ReactiveAuraState();
}

class _ReactiveAuraState extends State<ReactiveAura> with SingleTickerProviderStateMixin {
  late AnimationController _opController;

  @override
  void initState() {
    super.initState();
    _opController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(ReactiveAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.operator != oldWidget.operator && widget.operator != AuraOperator.none) {
      _opController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _opController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opController,
      builder: (context, child) {
        return CustomPaint(
          painter: AuraPainter(
            proximity: widget.proximity,
            timerProgress: widget.timerProgress,
            operator: widget.operator,
            operatorAnimation: _opController.value,
            baseColor: widget.baseColor,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class AuraPainter extends CustomPainter {
  final double proximity;
  final double timerProgress;
  final AuraOperator operator;
  final double operatorAnimation;
  final Color baseColor;
  final int timestamp;

  AuraPainter({
    required this.proximity,
    required this.timerProgress,
    required this.operator,
    required this.operatorAnimation,
    required this.baseColor,
    required this.timestamp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.8;

    // 1. Timer Panic: Shift to red and pulse
    final Color panicColor = Color.lerp(
      Colors.red.withValues(alpha: 0.8),
      baseColor,
      timerProgress.clamp(0.0, 1.0),
    ) ?? baseColor;

    // Pulse intensity increases as time runs out
    final double pulseSpeed = 1.0 + (4.0 * (1.0 - timerProgress));
    final double pulse = 1.0 + (0.05 * (1.0 - timerProgress) * sin(timestamp / 200 * pulseSpeed));

    // 2. Proximity Glow: Brighter as proximity nears 1.0 (exact match)
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          panicColor.withValues(alpha: 0.2 + (0.3 * proximity)),
          panicColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * pulse));

    canvas.drawCircle(center, radius * pulse, glowPaint);

    // 3. Operator Impact
    if (operator != AuraOperator.none && operatorAnimation > 0) {
      _drawOperatorEffect(canvas, size, center, operator, operatorAnimation, panicColor);
    }

    // 4. Subtle Ambient Waves
    _drawAmbientWaves(canvas, size, center, panicColor);
  }

  void _drawAmbientWaves(Canvas canvas, Size size, Offset center, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 1; i <= 3; i++) {
      final double waveProgress = (timestamp / (2000 * i)) % 1.0;
      final double waveRadius = size.shortestSide * 0.4 * waveProgress;
      paint.color = color.withValues(alpha: (1.0 - waveProgress) * 0.1);
      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  void _drawOperatorEffect(Canvas canvas, Size size, Offset center, AuraOperator op, double t, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * (1.0 - t);

    final double maxRadius = size.shortestSide * 0.5;

    switch (op) {
      case AuraOperator.plus:
        // Expanding ring
        paint.color = color.withValues(alpha: 1.0 - t);
        canvas.drawCircle(center, maxRadius * t, paint);
        break;
      case AuraOperator.minus:
        // Imploding ring
        paint.color = color.withValues(alpha: 1.0 - t);
        canvas.drawCircle(center, maxRadius * (1.0 - t), paint);
        break;
      case AuraOperator.times:
        // Starburst
        paint.color = color.withValues(alpha: 1.0 - t);
        for (int i = 0; i < 8; i++) {
          final double angle = i * pi / 4;
          final offset = Offset(cos(angle), sin(angle)) * maxRadius * t;
          canvas.drawLine(center, center + offset, paint);
        }
        break;
      case AuraOperator.divide:
        // Splitting lines
        paint.color = color.withValues(alpha: 1.0 - t);
        canvas.drawLine(
          center - Offset(maxRadius * t, maxRadius * t),
          center + Offset(maxRadius * t, maxRadius * t),
          paint,
        );
        canvas.drawLine(
          center - Offset(-maxRadius * t, maxRadius * t),
          center + Offset(-maxRadius * t, maxRadius * t),
          paint,
        );
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant AuraPainter oldDelegate) {
    return oldDelegate.timestamp != timestamp ||
        oldDelegate.proximity != proximity ||
        oldDelegate.timerProgress != timerProgress ||
        oldDelegate.operatorAnimation != operatorAnimation;
  }
}
