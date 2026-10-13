import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../music/presentation/cubit/music_cubit.dart';
import '../../music/presentation/cubit/music_state.dart';
import '../../music/presentation/cubit/player_cubit.dart';
import '../../music/presentation/widgets/track_tile.dart';
import 'package:pulse/features/music/domain/track.dart';
import 'package:pulse/features/music/domain/playlist.dart';
import 'playlist_details_screen.dart';
import '../../../core/widgets/smooth_scroller.dart';
import '../../../core/widgets/interactive_bounce_button.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0; // 0: Liked Songs, 1: Playlists
  final ScrollController _likedScrollController = ScrollController();
  final ScrollController _playlistScrollController = ScrollController();

  @override
  void dispose() {
    _likedScrollController.dispose();
    _playlistScrollController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = context.read<ThemeCubit>().state.isDark;
        final palette = context.read<ThemeCubit>().state.palette;
        final primaryAccent = AppColors.primaryColor(palette);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: isDark ? const Color(0xFF131520) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.6 : 0.25),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: AppColors.primaryGradient(palette),
                      ),
                      child: const Icon(Icons.queue_music_rounded, color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW PLAYLIST',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create Collection',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'e.g., Midnight Chill or Workout Beats',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InteractiveBounceButton(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InteractiveBounceButton(
                        onTap: () {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            context.read<MusicCubit>().createPlaylist(name);
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Created playlist "$name"'),
                                backgroundColor: AppColors.mintAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: AppColors.primaryGradient(palette),
                            boxShadow: [
                              BoxShadow(
                                color: primaryAccent.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Create',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);

    final musicState = context.watch<MusicCubit>().state;
    final playerState = context.watch<PlayerCubit>().state;

    final List<Track> favorites =
        (musicState is MusicLoaded) ? musicState.favorites : <Track>[];
    final List<Playlist> playlists =
        (musicState is MusicLoaded) ? musicState.playlists : <Playlist>[];

    // [WIDGET PURPOSE]: Scaffold
    // [LAYOUT PROBLEM SOLVED]: Serves as visual structure for the user's music library and playlists.
    // [BEHAVIOR & CONSTRAINTS]: Imposes bounds and theme styling.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // [WIDGET PURPOSE]: SafeArea
      // [LAYOUT PROBLEM SOLVED]: Ensures library header and controls avoid device cutouts.
      // [BEHAVIOR & CONSTRAINTS]: Resolves hardware insets.
      body: SafeArea(
        child: Column(
          children: [
            // Header Row with Title and Add Playlist Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY COLLECTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Library',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded, size: 28, color: primaryAccent),
                    onPressed: _showCreatePlaylistDialog,
                  ),
                ],
              ),
            ),

            // Tab Selector (Liked Songs vs Playlists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _selectedTab == 0
                            ? primaryAccent.withOpacity(isDark ? 0.2 : 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: _selectedTab == 0 ? primaryAccent : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        'Liked Songs (${favorites.length})',
                        style: TextStyle(
                          fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedTab == 0
                              ? primaryAccent
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _selectedTab == 1
                            ? primaryAccent.withOpacity(isDark ? 0.2 : 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: _selectedTab == 1 ? primaryAccent : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        'Playlists (${playlists.length})',
                        style: TextStyle(
                          fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedTab == 1
                              ? primaryAccent
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab Body Content
            Expanded(
              child: _selectedTab == 0
                  ? (favorites.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 54,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No liked songs yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap the heart on any song to save it here!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        )
                      : PulseSmoothScroller(
                          controller: _likedScrollController,
                          palette: palette,
                          isDark: isDark,
                          child: ListView.builder(
                            controller: _likedScrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: favorites.length,
                            itemBuilder: (context, index) {
                              final track = favorites[index];
                              final isCurrent = playerState.currentTrack?.id == track.id;
                              final isPlaying = isCurrent && playerState.isPlaying;

                              return SmoothSongTransition(
                                index: index,
                                child: TrackTile(
                                  track: track,
                                  isCurrent: isCurrent,
                                  isPlaying: isPlaying,
                                  isFavorite: true,
                                  palette: palette,
                                  isDark: isDark,
                                  onTap: () {
                                    context.read<PlayerCubit>().playTrack(
                                          track,
                                          playlist: favorites,
                                        );
                                  },
                                  onFavoriteToggle: () {
                                    context.read<MusicCubit>().toggleFavorite(track);
                                  },
                                ),
                              );
                            },
                          ),
                        ))
                  : (playlists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.queue_music_rounded,
                                size: 54,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No playlists yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Create a playlist to organize your favorite soundscapes!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: _showCreatePlaylistDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create Playlist'),
                              ),
                            ],
                          ),
                        )
                      : PulseSmoothScroller(
                          controller: _playlistScrollController,
                          palette: palette,
                          isDark: isDark,
                          child: ListView.builder(
                            controller: _playlistScrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: playlists.length + 1,
                            itemBuilder: (context, index) {
                            if (index == playlists.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                                    ),
                                    child: Icon(Icons.add_rounded, color: primaryAccent),
                                  ),
                                  title: const Text(
                                    'Create New Playlist',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  onTap: _showCreatePlaylistDialog,
                                ),
                              );
                            }

                            final pl = playlists[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                                ),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: AppColors.primaryGradient(palette),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryAccent.withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.queue_music_rounded, color: Colors.black),
                                ),
                                title: Text(
                                  pl.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '${pl.tracks.length} ${pl.tracks.length == 1 ? 'track' : 'tracks'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PlaylistDetailsScreen(playlistId: pl.id),
                                    ),
                                  );
                                },
                              ),
                            );
                            },
                          ),
                        )),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
