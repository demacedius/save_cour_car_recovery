import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';

class StepDot extends StatelessWidget {
  final bool isActive;

  const StepDot({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? FigmaColors.primaryMain : FigmaColors.neutral20,
        border: Border.all(
          color: isActive ? FigmaColors.primaryMain : FigmaColors.neutral20,
          width: 2,
        ),
      ),
    );
  }
}

class StepLine extends StatelessWidget {
  final bool isActive;

  const StepLine({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? const Color(0xFF6C63FF) : const Color(0xFFE4E4E4),
    );
  }
}