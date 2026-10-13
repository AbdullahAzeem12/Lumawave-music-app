import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/music/data/music_repository.dart';
import 'features/music/services/audio_player_service.dart';
import 'features/music/presentation/cubit/music_cubit.dart';
import 'features/music/presentation/cubit/player_cubit.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend for Auth, Profiles, and Cloud Library synchronization
  await SupabaseConfig.initialize();

  final authRepository = AuthRepository();
  final musicRepository = MusicRepository();
  final audioService = AudioPlayerService();

  runApp(
    LumaWaveApp(
      authRepository: authRepository,
      musicRepository: musicRepository,
      audioService: audioService,
    ),
  );
}

class LumaWaveApp extends StatelessWidget {
  final AuthRepository authRepository;
  final MusicRepository musicRepository;
  final AudioPlayerService audioService;

  const LumaWaveApp({
    super.key,
    required this.authRepository,
    required this.musicRepository,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    // [WIDGET PURPOSE]: MultiBlocProvider
    // [LAYOUT PROBLEM SOLVED]: Injects theme, auth, music, and audio player state down the complete widget tree.
    return RepositoryProvider<AuthRepository>.value(
      value: authRepository,
      child: MultiBlocProvider(
        providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepository),
        ),
        BlocProvider<MusicCubit>(
          create: (context) => MusicCubit(
            musicRepository: musicRepository,
            authRepository: authRepository,
          ),
        ),
        BlocProvider<PlayerCubit>(
          create: (context) => PlayerCubit(
            audioService: audioService,
            musicRepository: musicRepository,
          ),
        ),
      ],
      // [WIDGET PURPOSE]: BlocBuilder<ThemeCubit, ThemeState>
      // [LAYOUT PROBLEM SOLVED]: Dynamically rebuilds MaterialApp whenever the user switches between Light/Dark or changes the 4 palettes.
      // [BEHAVIOR & CONSTRAINTS]: Listens to ThemeState and updates themeData.
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          // [WIDGET PURPOSE]: MaterialApp
          // [LAYOUT PROBLEM SOLVED]: Configures root routing, Material 3 design tokens, typography, and initial screen.
          // [BEHAVIOR & CONSTRAINTS]: Mounts SplashScreen and sets dark/light themes.
          return MaterialApp(
            title: 'LumaWave - 3D Music',
            debugShowCheckedModeBanner: false,
            themeMode: themeState.themeMode,
            theme: AppTheme.buildTheme(
              palette: themeState.palette,
              isDark: false,
            ),
            darkTheme: AppTheme.buildTheme(
              palette: themeState.palette,
              isDark: true,
            ),
            home: const SplashScreen(),
          );
        },
      ),
    ),
  );
}
}
