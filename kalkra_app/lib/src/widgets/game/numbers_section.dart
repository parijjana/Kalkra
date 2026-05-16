import 'package:flutter/material.dart';
import 'number_tile.dart';

class NumbersSection extends StatelessWidget {
  final List<int> numbers;
  final List<int> usedIndices;
  final Function(int, int) onNumberTap;
  final Animation<double> entranceAnimation;
  final int focusedIndex;
  final bool isHorizontal;
  const NumbersSection({
    super.key,
    required this.numbers,
    required this.usedIndices,
    required this.onNumberTap,
    required this.entranceAnimation,
    required this.focusedIndex,
    this.isHorizontal = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: isHorizontal ? 32 : 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(numbers.length, (i) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: entranceAnimation,
              curve: Interval(0.2 + (i * 0.1), 1.0, curve: Curves.elasticOut),
            ),
            child: NumberTile(
              value: numbers[i],
              isUsed: usedIndices.contains(i),
              isFocused: i == focusedIndex,
              onTap: () => onNumberTap(i, numbers[i]),
              small: !isHorizontal,
            ),
          );
        }),
      ),
    );
  }
}
