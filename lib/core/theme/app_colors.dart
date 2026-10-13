import 'package:flutter/material.dart';

/// Available Color Palette styles for LumaWave
enum AppPalette {
  obsidianAurora, // Cyan & Violet on Deep Midnight
  pearlPrism,     // Lilac & Rose on Crisp Alabaster / Mist
  emeraldSound,   // Mint & Forest Cyan on Abyssal Green
  velvetSunset,   // Magenta & Solar Amber on Royal Plum
}

/// Central color definitions and theme token resolvers
class AppColors {
  // Common Accents
  static const Color cyanAccent = Color(0xFF00F2FE);
  static const Color violetAccent = Color(0xFF4FACFE);
  static const Color lilacAccent = Color(0xFFA18CD1);
  static const Color roseAccent = Color(0xFFFBC2EB);
  static const Color mintAccent = Color(0xFF00F5A0);
  static const Color emeraldAccent = Color(0xFF00D9F5);
  static const Color magentaAccent = Color(0xFFFA709A);
  static const Color amberAccent = Color(0xFFFEE140);

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF3366);
  static const Color info = Color(0xFF29B6F6);

  // Palette 1: Obsidian Aurora (Midnight / Cyan / Violet)
  static const Color obsidianDarkBg = Color(0xFF0A0C16);
  static const Color obsidianDarkSurface = Color(0xFF131728);
  static const Color obsidianLightBg = Color(0xFFF8FAFC);
  static const Color obsidianLightSurface = Color(0xFFFFFFFF);

  // Palette 2: Pearl Prism (Charcoal Mist / Pure Alabaster / Lilac)
  static const Color pearlDarkBg = Color(0xFF12131C);
  static const Color pearlDarkSurface = Color(0xFF1E1F2E);
  static const Color pearlLightBg = Color(0xFFFFFFFF);
  static const Color pearlLightSurface = Color(0xFFF1F3F9);

  // Palette 3: Emerald Sound (Abyssal Green / Mint)
  static const Color emeraldDarkBg = Color(0xFF071611);
  static const Color emeraldDarkSurface = Color(0xFF0D241C);
  static const Color emeraldLightBg = Color(0xFFF2F9F6);
  static const Color emeraldLightSurface = Color(0xFFFFFFFF);

  // Palette 4: Velvet Sunset (Royal Plum / Sunset Magenta)
  static const Color velvetDarkBg = Color(0xFF170B14);
  static const Color velvetDarkSurface = Color(0xFF241220);
  static const Color velvetLightBg = Color(0xFFFDF7F9);
  static const Color velvetLightSurface = Color(0xFFFFFFFF);

  /// Resolves the primary gradient according to the active palette
  static LinearGradient primaryGradient(AppPalette palette) {
    switch (palette) {
      case AppPalette.obsidianAurora:
        return const LinearGradient(
          colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppPalette.pearlPrism:
        return const LinearGradient(
          colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppPalette.emeraldSound:
        return const LinearGradient(
          colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppPalette.velvetSunset:
        return const LinearGradient(
          colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// Resolves the primary accent color
  static Color primaryColor(AppPalette palette) {
    switch (palette) {
      case AppPalette.obsidianAurora:
        return cyanAccent;
      case AppPalette.pearlPrism:
        return lilacAccent;
      case AppPalette.emeraldSound:
        return mintAccent;
      case AppPalette.velvetSunset:
        return magentaAccent;
    }
  }

  /// Resolves the secondary accent color
  static Color secondaryColor(AppPalette palette) {
    switch (palette) {
      case AppPalette.obsidianAurora:
        return violetAccent;
      case AppPalette.pearlPrism:
        return roseAccent;
      case AppPalette.emeraldSound:
        return emeraldAccent;
      case AppPalette.velvetSunset:
        return amberAccent;
    }
  }

  /// Background color based on palette and dark mode
  static Color backgroundColor(AppPalette palette, bool isDark) {
    if (isDark) {
      switch (palette) {
        case AppPalette.obsidianAurora:
          return obsidianDarkBg;
        case AppPalette.pearlPrism:
          return pearlDarkBg;
        case AppPalette.emeraldSound:
          return emeraldDarkBg;
        case AppPalette.velvetSunset:
          return velvetDarkBg;
      }
    } else {
      switch (palette) {
        case AppPalette.obsidianAurora:
          return obsidianLightBg;
        case AppPalette.pearlPrism:
          return pearlLightBg;
        case AppPalette.emeraldSound:
          return emeraldLightBg;
        case AppPalette.velvetSunset:
          return velvetLightBg;
      }
    }
  }

  /// Surface card color based on palette and dark mode
  static Color surfaceColor(AppPalette palette, bool isDark) {
    if (isDark) {
      switch (palette) {
        case AppPalette.obsidianAurora:
          return obsidianDarkSurface;
        case AppPalette.pearlPrism:
          return pearlDarkSurface;
        case AppPalette.emeraldSound:
          return emeraldDarkSurface;
        case AppPalette.velvetSunset:
          return velvetDarkSurface;
      }
    } else {
      switch (palette) {
        case AppPalette.obsidianAurora:
          return obsidianLightSurface;
        case AppPalette.pearlPrism:
          return pearlLightSurface;
        case AppPalette.emeraldSound:
          return emeraldLightSurface;
        case AppPalette.velvetSunset:
          return velvetLightSurface;
      }
    }
  }
}
