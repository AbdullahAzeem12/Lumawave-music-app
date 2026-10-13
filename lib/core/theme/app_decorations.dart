import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 3D Glassmorphic, Neumorphic, and Specular highlight decorations
class AppDecorations {
  /// 3D Floating Glass Card with specular top border and dual-layer chromatic shadow
  static BoxDecoration glassCard3D({
    required BuildContext context,
    required AppPalette palette,
    required bool isDark,
    double borderRadius = 24.0,
    bool isHovered = false,
  }) {
    final accent = AppColors.primaryColor(palette);
    final secondary = AppColors.secondaryColor(palette);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      // Translucent glass gradient surface
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(isHovered ? 0.16 : 0.10),
                Colors.white.withOpacity(isHovered ? 0.08 : 0.04),
              ]
            : [
                Colors.white.withOpacity(isHovered ? 0.95 : 0.88),
                Colors.white.withOpacity(isHovered ? 0.85 : 0.72),
              ],
      ),
      // Specular Top-Edge Highlighting Border
      border: Border.all(
        color: isHovered
            ? accent.withOpacity(0.65)
            : (isDark ? Colors.white.withOpacity(0.22) : accent.withOpacity(0.35)),
        width: isHovered ? 1.6 : 1.2,
      ),
      // Dual-Layer Chromatic Shadow System
      boxShadow: [
        // 1. Ambient Occlusion dark depth shadow
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
          blurRadius: isHovered ? 28 : 20,
          spreadRadius: 0,
          offset: Offset(0, isHovered ? 12 : 8),
        ),
        // 2. Neon Backlight Chromatic Glow
        BoxShadow(
          color: (isHovered ? accent : secondary).withOpacity(isDark ? 0.22 : 0.10),
          blurRadius: isHovered ? 32 : 22,
          spreadRadius: -4,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 3D Glowing Button with vibrant gradient, specular edge, and neon spread
  static BoxDecoration primary3DButton({
    required AppPalette palette,
    bool isPressed = false,
    double borderRadius = 999.0,
  }) {
    final accent = AppColors.primaryColor(palette);
    final secondary = AppColors.secondaryColor(palette);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: [accent, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.4),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(isPressed ? 0.4 : 0.6),
          blurRadius: isPressed ? 14 : 24,
          spreadRadius: isPressed ? -2 : 0,
          offset: Offset(0, isPressed ? 4 : 8),
        ),
        BoxShadow(
          color: secondary.withOpacity(0.3),
          blurRadius: 16,
          spreadRadius: -4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 3D Floating Glass Dock (used for persistent Mini-Player & Bottom Nav)
  static BoxDecoration glassDock({
    required BuildContext context,
    required AppPalette palette,
    required bool isDark,
    double borderRadius = 28.0,
  }) {
    final accent = AppColors.primaryColor(palette);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF161A2E).withOpacity(0.88),
                const Color(0xFF0C0E1A).withOpacity(0.95),
              ]
            : [
                Colors.white.withOpacity(0.92),
                const Color(0xFFF1F5F9).withOpacity(0.88),
              ],
      ),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.18) : accent.withOpacity(0.25),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
          blurRadius: 30,
          spreadRadius: 2,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: accent.withOpacity(0.2),
          blurRadius: 24,
          spreadRadius: -2,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  /// Ambient Radial Glow Mesh (placed in background Stack)
  static Widget ambientGlowOrb({
    required Color color,
    required double size,
    double opacity = 0.35,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
