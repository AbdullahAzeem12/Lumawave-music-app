import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/interactive_bounce_button.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AppPalette palette;
  final bool isDark;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.palette,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryAccent = AppColors.primaryColor(palette);

    // [WIDGET PURPOSE]: InteractiveBounceButton
    // [LAYOUT PROBLEM SOLVED]: Micro-spring rapid bounce back effect with zero input latency.
    // [BEHAVIOR & CONSTRAINTS]: Bounds hit testing to the chip's decorated pill area.
    return InteractiveBounceButton(
      pressScale: 0.92,
      onTap: onTap,
      // [WIDGET PURPOSE]: AnimatedContainer
      // [LAYOUT PROBLEM SOLVED]: Animates color, elevation, and border transitions smoothly when toggled.
      // [BEHAVIOR & CONSTRAINTS]: Implicitly animates between selected and unselected states over 250ms.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: isSelected
              ? AppColors.primaryGradient(palette)
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.4)
                : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryAccent.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        // [WIDGET PURPOSE]: Text
        // [LAYOUT PROBLEM SOLVED]: Displays category name with high-contrast typography.
        // [BEHAVIOR & CONSTRAINTS]: Shrink-wraps horizontally within the chip padding.
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.black
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
