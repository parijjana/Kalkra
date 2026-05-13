import 'dart:async';
import 'package:flutter/material.dart';

class CountdownOverlay extends StatefulWidget {
  final int targetTimeMillis;
  final VoidCallback onComplete;

  const CountdownOverlay({
    super.key,
    required this.targetTimeMillis,
    required this.onComplete,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with TickerProviderStateMixin {
  late Timer _timer;
  int _secondsRemaining = 3;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _startCountdown();
  }

  void _startCountdown() {
    _updateSeconds();
    _controller.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = widget.targetTimeMillis - now;

      final newSeconds = (diff / 1000).ceil();
      if (newSeconds != _secondsRemaining) {
        if (newSeconds <= 0) {
          _timer.cancel();
          widget.onComplete();
        } else {
          setState(() {
            _secondsRemaining = newSeconds;
          });
          _controller.forward(from: 0.0);
        }
      }
    });
  }

  void _updateSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _secondsRemaining = ((widget.targetTimeMillis - now) / 1000).ceil();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  '$_secondsRemaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
