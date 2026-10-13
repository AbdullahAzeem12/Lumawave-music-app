import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../music/presentation/cubit/music_cubit.dart';
import '../../music/presentation/cubit/music_state.dart';
import '../../music/presentation/cubit/player_cubit.dart';
import '../../music/presentation/widgets/track_tile.dart';
import '../../../core/widgets/smooth_scroller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  static const List<String> _quickTags = [
    'Bollywood Hits',
    'Audius Originals',
    'Jamendo CC',
    'Non-Copyright Indian',
    'Arijit Singh',
    'Dua Lipa',
    'Chill Lo-Fi',
    'Synthwave EDM',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      context.read<MusicCubit>().search(query);
    });
  }

  void _setQuery(String query) {
    _searchController.text = query;
    context.read<MusicCubit>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);

    final musicState = context.watch<MusicCubit>().state;
    final playerState = context.watch<PlayerCubit>().state;

    // [WIDGET PURPOSE]: Scaffold
    // [LAYOUT PROBLEM SOLVED]: Serves as base layout for real-time live search.
    // [BEHAVIOR & CONSTRAINTS]: Imposes bounds and theme styling.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // [WIDGET PURPOSE]: SafeArea
      // [LAYOUT PROBLEM SOLVED]: Keeps search field away from top camera cutout.
      // [BEHAVIOR & CONSTRAINTS]: Resolves hardware insets.
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              // [WIDGET PURPOSE]: Container
              // [LAYOUT PROBLEM SOLVED]: Creates the 3D glowing glass border for the search bar.
              // [BEHAVIOR & CONSTRAINTS]: Border radius 22px with subtle shadow.
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.0),
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                    width: 1.2,
                  ),
                ),
                // [WIDGET PURPOSE]: TextField
                // [LAYOUT PROBLEM SOLVED]: Captures keyboard input with instant clear and debounce listeners.
                // [BEHAVIOR & CONSTRAINTS]: Autofocus false, TextInputAction search.
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, or genres...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              context.read<MusicCubit>().search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Quick Tags Row
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                itemCount: _quickTags.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = _quickTags[index];
                  return GestureDetector(
                    onTap: () => _setQuery(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Search Results Section
            Expanded(
              child: (musicState is MusicLoaded && musicState.isSearching)
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                      ),
                    )
                  : (musicState is MusicLoaded && musicState.searchResults.isNotEmpty)
                      ? PulseSmoothScroller(
                          controller: _scrollController,
                          palette: palette,
                          isDark: isDark,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: musicState.searchResults.length,
                            itemBuilder: (context, index) {
                              final track = musicState.searchResults[index];
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
                                          playlist: musicState.searchResults,
                                        );
                                  },
                                  onFavoriteToggle: () {
                                    context.read<MusicCubit>().toggleFavorite(track);
                                  },
                                ),
                              );
                            },
                          ),
                        )
                      : (musicState is MusicLoaded && _searchController.text.isNotEmpty)
                          ? Center(
                              child: Text(
                                'No matching songs found',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            )
                          : (musicState is MusicLoaded)
                              ? PulseSmoothScroller(
                                  controller: _scrollController,
                                  palette: palette,
                                  isDark: isDark,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: musicState.catalog.allTracks.take(20).length,
                                    itemBuilder: (context, index) {
                                      final track = musicState.catalog.allTracks[index];
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
                                                  playlist: musicState.catalog.allTracks,
                                                );
                                          },
                                          onFavoriteToggle: () {
                                            context.read<MusicCubit>().toggleFavorite(track);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
