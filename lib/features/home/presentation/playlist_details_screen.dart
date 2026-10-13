import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../music/presentation/cubit/music_cubit.dart';
import '../../music/presentation/cubit/music_state.dart';
import '../../music/presentation/cubit/player_cubit.dart';
import '../../music/presentation/widgets/track_tile.dart';
import '../../music/presentation/widgets/mini_player.dart';
import '../../music/domain/track.dart';
import '../../../core/widgets/smooth_scroller.dart';
import '../../../core/widgets/interactive_bounce_button.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlistId,
  });

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
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
    final secondaryAccent = AppColors.secondaryColor(palette);

    final musicState = context.watch<MusicCubit>().state;
    final playerState = context.watch<PlayerCubit>().state;

    if (musicState is! MusicLoaded) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor(palette, isDark),
        appBar: AppBar(title: const Text('Playlist')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final playlistIndex = musicState.playlists.indexWhere((p) => p.id == widget.playlistId);
    if (playlistIndex == -1) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor(palette, isDark),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.playlist_remove_rounded, size: 54, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Playlist not found or was removed'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Library'),
              ),
            ],
          ),
        ),
      );
    }

    final playlist = musicState.playlists[playlistIndex];
    final tracks = playlist.tracks;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(palette, isDark),
      body: Stack(
        children: [
          // Ambient Glow Top Left
          Positioned(
            top: -60,
            left: -60,
            child: AppDecorations.ambientGlowOrb(
              color: primaryAccent,
              size: 320,
              opacity: 0.35,
            ),
          ),

          // Ambient Glow Bottom Right
          Positioned(
            bottom: -60,
            right: -60,
            child: AppDecorations.ambientGlowOrb(
              color: secondaryAccent,
              size: 300,
              opacity: 0.25,
            ),
          ),

          SafeArea(
            child: PulseSmoothScroller(
              controller: _scrollController,
              palette: palette,
              isDark: isDark,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InteractiveBounceButton(
                          pressScale: 0.88,
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: AppColors.surfaceColor(palette, isDark),
                          onSelected: (value) {
                            if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      color: isDark ? const Color(0xFF131520) : Colors.white,
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.35),
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
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.error.withOpacity(0.18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.error.withOpacity(0.3),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.delete_forever_rounded,
                                            color: AppColors.error,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Delete Playlist?',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Are you sure you want to permanently delete "${playlist.name}"?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InteractiveBounceButton(
                                                pressScale: 0.94,
                                                onTap: () => Navigator.pop(ctx),
                                                child: Container(
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                                                    border: Border.all(
                                                      color: isDark ? Colors.white12 : Colors.black12,
                                                    ),
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
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: InteractiveBounceButton(
                                                pressScale: 0.94,
                                                onTap: () {
                                                  Navigator.pop(ctx);
                                                  context.read<MusicCubit>().deletePlaylist(playlist.id);
                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    color: AppColors.error,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors.error.withOpacity(0.4),
                                                        blurRadius: 14,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 14,
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
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete Playlist', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Playlist Hero Header Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: AppDecorations.glassCard3D(
                        context: context,
                        palette: palette,
                        isDark: isDark,
                        borderRadius: 28,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: AppColors.primaryGradient(palette),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryAccent.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.queue_music_rounded,
                              size: 46,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            playlist.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (playlist.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              playlist.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '${tracks.length} ${tracks.length == 1 ? 'Track' : 'Tracks'} • Custom Playlist',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryAccent,
                            ),
                          ),
                          if (tracks.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InteractiveBounceButton(
                                  pressScale: 0.94,
                                  onTap: () {
                                    context.read<PlayerCubit>().playTrack(
                                          tracks.first,
                                          playlist: tracks,
                                        );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: AppColors.primaryGradient(palette),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryAccent.withOpacity(0.4),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                                        SizedBox(width: 6),
                                        Text(
                                          'Play All',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                InteractiveBounceButton(
                                  pressScale: 0.94,
                                  onTap: () {
                                    final shuffled = List<Track>.from(tracks)..shuffle();
                                    context.read<PlayerCubit>().playTrack(
                                          shuffled.first,
                                          playlist: shuffled,
                                        );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.black26,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shuffle_rounded,
                                          size: 20,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Shuffle',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Tracks List or Empty State
                if (tracks.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.music_off_rounded,
                              size: 50,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'This playlist is empty',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Find tracks in Home or Search and tap "Add to Playlist"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
                        final isCurrent = playerState.currentTrack?.id == track.id;
                        final isPlaying = isCurrent && playerState.isPlaying;
                        final isFav = musicState.favorites.any((t) => t.id == track.id);

                        return Dismissible(
                          key: Key('pl_${playlist.id}_${track.id}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            context.read<MusicCubit>().removeTrackFromPlaylist(playlist.id, track.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed "${track.title}" from ${playlist.name}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: SmoothSongTransition(
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
                                      playlist: tracks,
                                    );
                              },
                              onFavoriteToggle: () {
                                context.read<MusicCubit>().toggleFavorite(track);
                              },
                            ),
                          ),
                        );
                      },
                      childCount: tracks.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),

          // Mini Player Dock
          const Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
