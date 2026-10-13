import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../music/presentation/cubit/music_cubit.dart';
import '../../../core/widgets/smooth_scroller.dart';

class DiscoverScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;

  const DiscoverScreen({
    super.key,
    required this.onNavigateToHome,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _genres = [
    {
      'title': 'Bollywood Hits',
      'category': 'Bollywood',
      'colors': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      'icon': Icons.local_fire_department_rounded,
      'subtitle': 'Top Hindi Film Soundtracks',
    },
    {
      'title': 'Hollywood Top 50',
      'category': 'Hollywood',
      'colors': [Color(0xFF2193B0), Color(0xFF6DD5ED)],
      'icon': Icons.star_rounded,
      'subtitle': 'Billboard & Global Pop',
    },
    {
      'title': 'Indie Waves',
      'category': 'Indie',
      'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      'icon': Icons.waves_rounded,
      'subtitle': 'Independent & CC Originals',
    },
    {
      'title': 'Lo-Fi Chill & Focus',
      'category': 'All',
      'colors': [Color(0xFF11998E), Color(0xFF38EF7D)],
      'icon': Icons.headphones_rounded,
      'subtitle': 'Relaxing Study Beats',
    },
    {
      'title': 'EDM & Cyberwave',
      'category': 'All',
      'colors': [Color(0xFFF857A6), Color(0xFFFF5858)],
      'icon': Icons.electric_bolt_rounded,
      'subtitle': 'High-Energy Electronic',
    },
    {
      'title': 'Acoustic & Soul',
      'category': 'All',
      'colors': [Color(0xFFF7971E), Color(0xFFFFD200)],
      'icon': Icons.piano_rounded,
      'subtitle': 'Intimate Unplugged Melodies',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;

    // [WIDGET PURPOSE]: Scaffold
    // [LAYOUT PROBLEM SOLVED]: Provides the view canvas for the Discover & Mood explorer page.
    // [BEHAVIOR & CONSTRAINTS]: Imposes bounds and background theme styling.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // [WIDGET PURPOSE]: SafeArea
      // [LAYOUT PROBLEM SOLVED]: Protects header and grid from top screen camera notch.
      // [BEHAVIOR & CONSTRAINTS]: Resolves hardware insets.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          // [WIDGET PURPOSE]: PulseSmoothScroller
          // [LAYOUT PROBLEM SOLVED]: Unifies title and grid into a single smooth scroll view with interactive glowing scrollbar.
          // [BEHAVIOR & CONSTRAINTS]: 60/120fps smooth scrolling.
          child: PulseSmoothScroller(
            controller: _scrollController,
            palette: palette,
            isDark: isDark,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPLORE GENRES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: AppColors.primaryColor(palette),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discover by Mood',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // [WIDGET PURPOSE]: SliverGrid
              // [LAYOUT PROBLEM SOLVED]: Renders responsive 2-column 3D dimensional genre cards.
              // [BEHAVIOR & CONSTRAINTS]: SliverGridDelegateWithFixedCrossAxisCount with crossAxisCount 2.
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14.0,
                  mainAxisSpacing: 14.0,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _genres[index];
                    final List<Color> colors = item['colors'];

                    // [WIDGET PURPOSE]: GestureDetector
                    // [LAYOUT PROBLEM SOLVED]: Captures taps on the genre card to filter the catalog.
                    // [BEHAVIOR & CONSTRAINTS]: Triggers category filtering and returns to dashboard.
                    return SmoothSongTransition(
                      index: index,
                      child: GestureDetector(
                        onTap: () {
                          context.read<MusicCubit>().filterCategory(item['category']);
                          widget.onNavigateToHome();
                        },
                        // [WIDGET PURPOSE]: Container
                        // [LAYOUT PROBLEM SOLVED]: The physical 3D dimensional surface with specular border and glow.
                        // [BEHAVIOR & CONSTRAINTS]: Fits grid cell constraints.
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.0),
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.first.withOpacity(0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          // [WIDGET PURPOSE]: Column
                          // [LAYOUT PROBLEM SOLVED]: Arranges icon at top-right and title/subtitle at bottom-left.
                          // [BEHAVIOR & CONSTRAINTS]: SpaceBetween mainAxisAlignment.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.25),
                                  ),
                                  child: Icon(
                                    item['icon'],
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['subtitle'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _genres.length,
                ),
              ),

              // Bottom Padding for Mini-Player
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
