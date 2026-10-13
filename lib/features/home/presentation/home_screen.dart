import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../../music/presentation/cubit/music_cubit.dart';
import '../../music/presentation/cubit/music_state.dart';
import '../../music/presentation/cubit/player_cubit.dart';
import '../../music/presentation/widgets/category_chip.dart';
import '../../music/presentation/widgets/hero_carousel.dart';
import '../../music/presentation/widgets/track_tile.dart';
import '../../../core/widgets/smooth_scroller.dart';
import '../../../core/widgets/interactive_bounce_button.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToSearch;

  const HomeScreen({
    super.key,
    required this.onNavigateToSearch,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);

    final authState = context.watch<AuthCubit>().state;
    final user = (authState is Authenticated) ? authState.user : null;
    final userName = user?.displayName ?? 'Explorer';

    final musicState = context.watch<MusicCubit>().state;
    final playerState = context.watch<PlayerCubit>().state;

    // [WIDGET PURPOSE]: Scaffold
    // [LAYOUT PROBLEM SOLVED]: Establishes the visual canvas for the Home discovery dashboard.
    // [BEHAVIOR & CONSTRAINTS]: Imposes bounds and background theme coloring.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // [WIDGET PURPOSE]: SafeArea
      // [LAYOUT PROBLEM SOLVED]: Keeps dashboard header and scroll views away from hardware status bar.
      // [BEHAVIOR & CONSTRAINTS]: Applies dynamic safe insets.
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryAccent,
          backgroundColor: isDark ? const Color(0xFF1E2438) : Colors.white,
          onRefresh: () => context.read<MusicCubit>().loadCatalog(force: true),
          // [WIDGET PURPOSE]: PulseSmoothScroller
          // [LAYOUT PROBLEM SOLVED]: Wraps CustomScrollView with interactive glowing scrollbar and buttery smooth friction.
          // [BEHAVIOR & CONSTRAINTS]: Smooth, hardware-accelerated 60/120fps scrolling.
          child: PulseSmoothScroller(
            controller: _scrollController,
            palette: palette,
            isDark: isDark,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // Top App Bar / Greeting Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    // [WIDGET PURPOSE]: Row
                    // [LAYOUT PROBLEM SOLVED]: Places greeting text on the left and search/refresh buttons on the right without overflowing.
                    // [BEHAVIOR & CONSTRAINTS]: Flex-balanced with MainAxisSize.min on actions to prevent pixel overflows.
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Greeting Column with optional profile photo
                        Expanded(
                          child: Row(
                            children: [
                              if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) ...[
                                InteractiveBounceButton(
                                  pressScale: 0.90,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient(palette),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryAccent.withOpacity(0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(2.0),
                                    child: ClipOval(
                                      child: _buildHomeAvatar(user.photoUrl, userName, primaryAccent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'HELLO, $userName'.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.8,
                                        color: primaryAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Immersive Sound',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Actions Row (Refresh & Search) - strictly constrained to prevent overflow
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Refresh Button with rapid interactive bounce
                            InteractiveBounceButton(
                              pressScale: 0.90,
                              onTap: () => context.read<MusicCubit>().loadCatalog(force: true),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                  ),
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Quick Search Button with rapid interactive bounce
                            InteractiveBounceButton(
                              pressScale: 0.90,
                              onTap: widget.onNavigateToSearch,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                  ),
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

            // Category Filter Chips Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                // [WIDGET PURPOSE]: SizedBox
                // [LAYOUT PROBLEM SOLVED]: Clamps the vertical height of the horizontal category chips list.
                // [BEHAVIOR & CONSTRAINTS]: Exactly 46 pixels height.
                child: SizedBox(
                  height: 46,
                  // [WIDGET PURPOSE]: ListView
                  // [LAYOUT PROBLEM SOLVED]: Horizontally scrolls category selection chips.
                  // [BEHAVIOR & CONSTRAINTS]: Axis horizontal with BouncingScrollPhysics.
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      CategoryChip(
                        label: 'All Releases',
                        isSelected: (musicState is MusicLoaded) && musicState.activeCategory == 'All',
                        palette: palette,
                        isDark: isDark,
                        onTap: () => context.read<MusicCubit>().filterCategory('All'),
                      ),
                      const SizedBox(width: 8),
                      CategoryChip(
                        label: 'Bollywood Hits',
                        isSelected: (musicState is MusicLoaded) && musicState.activeCategory == 'Bollywood',
                        palette: palette,
                        isDark: isDark,
                        onTap: () => context.read<MusicCubit>().filterCategory('Bollywood'),
                      ),
                      const SizedBox(width: 8),
                      CategoryChip(
                        label: 'Hollywood & Top 50',
                        isSelected: (musicState is MusicLoaded) && musicState.activeCategory == 'Hollywood',
                        palette: palette,
                        isDark: isDark,
                        onTap: () => context.read<MusicCubit>().filterCategory('Hollywood'),
                      ),
                      const SizedBox(width: 8),
                      CategoryChip(
                        label: 'Indie Waves',
                        isSelected: (musicState is MusicLoaded) && musicState.activeCategory == 'Indie',
                        palette: palette,
                        isDark: isDark,
                        onTap: () => context.read<MusicCubit>().filterCategory('Indie'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Hero 3D Featured Carousel
            if (musicState is MusicLoaded && musicState.catalog.featured.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: HeroCarousel(
                  tracks: musicState.catalog.featured,
                  palette: palette,
                  isDark: isDark,
                  onPlayTrack: (track) {
                    context.read<PlayerCubit>().playTrack(
                          track,
                          playlist: musicState.catalog.featured,
                        );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // Section Header: Dynamic Live Tracks (200+ Songs)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (musicState is MusicLoaded)
                            ? '${musicState.activeCategory} Songs (${musicState.filteredTracks.length})'
                            : 'Live Songs',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jamendo • Audius • iTunes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Track List / Loading / Error State
            if (musicState is MusicLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading live songs simultaneously from Jamendo, Audius & iTunes libraries...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (musicState is MusicLoaded)
              // [WIDGET PURPOSE]: SliverList
              // [LAYOUT PROBLEM SOLVED]: Lazily builds the 200+ song items as the user scrolls, preserving 60fps.
              // [BEHAVIOR & CONSTRAINTS]: Recycles list items efficiently in viewport.
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = musicState.filteredTracks[index];
                    final isCurrent = playerState.currentTrack?.id == track.id;
                    final isPlaying = isCurrent && playerState.isPlaying;
                    final isFav = musicState.favorites.any((t) => t.id == track.id);

                    return SmoothSongTransition(
                      index: index,
                      child: TrackTile(
                        track: track,
                        isCurrent: isCurrent,
                        isPlaying: isPlaying,
                        isFavorite: isFav,
                        palette: palette,
                        isDark: isDark,
                        onTap: () {
                          context.read<PlayerCubit>().playTrack(
                                track,
                                playlist: musicState.filteredTracks,
                              );
                        },
                        onFavoriteToggle: () {
                          context.read<MusicCubit>().toggleFavorite(track);
                        },
                      ),
                    );
                  },
                  childCount: musicState.filteredTracks.length,
                ),
              )
            else if (musicState is MusicError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(musicState.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<MusicCubit>().loadCatalog(force: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Spacing for Persistent Mini-Player Dock
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildHomeAvatar(String? photoUrl, String userName, Color primaryAccent) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return _buildAvatarInitials(userName, primaryAccent);
    }

    if (photoUrl.startsWith('data:image') ||
        (!photoUrl.startsWith('http://') && !photoUrl.startsWith('https://') && photoUrl.length > 80)) {
      try {
        final base64String = photoUrl.contains(',')
            ? photoUrl.split(',').last.trim()
            : photoUrl.trim();
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildAvatarInitials(userName, primaryAccent),
        );
      } catch (_) {
        return _buildAvatarInitials(userName, primaryAccent);
      }
    }

    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.black12),
        errorWidget: (_, __, ___) => _buildAvatarInitials(userName, primaryAccent),
      );
    }

    return _buildAvatarInitials(userName, primaryAccent);
  }

  Widget _buildAvatarInitials(String userName, Color primaryAccent) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}


