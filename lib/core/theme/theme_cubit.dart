import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final AppPalette palette;

  const ThemeState({
    required this.themeMode,
    required this.palette,
  });

  bool get isDark {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    // Default to dark for high-contrast aesthetic if system
    return true;
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppPalette? palette,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
    );
  }

  @override
  List<Object?> get props => [themeMode, palette];
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _prefThemeMode = 'app_theme_mode';
  static const String _prefPalette = 'app_theme_palette';

  ThemeCubit()
      : super(const ThemeState(
          themeMode: ThemeMode.dark,
          palette: AppPalette.obsidianAurora,
        )) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_prefThemeMode) ?? ThemeMode.dark.index;
      final paletteIndex = prefs.getInt(_prefPalette) ?? AppPalette.obsidianAurora.index;

      emit(ThemeState(
        themeMode: ThemeMode.values[modeIndex],
        palette: AppPalette.values[paletteIndex],
      ));
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeMode, mode.index);
  }

  Future<void> setPalette(AppPalette palette) async {
    emit(state.copyWith(palette: palette));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefPalette, palette.index);
  }

  Future<void> toggleBrightness() async {
    final nextMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
