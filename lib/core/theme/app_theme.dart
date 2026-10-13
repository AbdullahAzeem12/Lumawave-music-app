import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Produces refined ThemeData for any Palette & Brightness mode
class AppTheme {
  static ThemeData buildTheme({
    required AppPalette palette,
    required bool isDark,
  }) {
    final bg = AppColors.backgroundColor(palette, isDark);
    final surface = AppColors.surfaceColor(palette, isDark);
    final primary = AppColors.primaryColor(palette);
    final secondary = AppColors.secondaryColor(palette);

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primary,
            secondary: secondary,
            surface: surface,
            background: bg,
            error: AppColors.error,
            onPrimary: Colors.black,
            onSecondary: Colors.black,
            onSurface: Colors.white,
            onBackground: Colors.white,
          )
        : ColorScheme.light(
            primary: primary,
            secondary: secondary,
            surface: surface,
            background: bg,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF1E293B),
            onBackground: const Color(0xFF0F172A),
          );

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = GoogleFonts.outfitTextTheme(baseTextTheme).apply(
      bodyColor: isDark ? Colors.white : const Color(0xFF1E293B),
      displayColor: isDark ? Colors.white : const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      textTheme: textTheme,
      cardColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
        thumbColor: Colors.white,
        overlayColor: primary.withOpacity(0.2),
        trackHeight: 4.0,
      ),
    );
  }
}
