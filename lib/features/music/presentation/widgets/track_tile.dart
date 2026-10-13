import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../domain/track.dart';
import '../../domain/playlist.dart';
import '../../../../core/widgets/interactive_bounce_button.dart';
import '../cubit/music_cubit.dart';
import '../cubit/music_state.dart';

class TrackTile extends StatefulWidget {
  final Track track;
  final bool isCurrent;
  final bool isPlaying;
  final bool isFavorite;
  final AppPalette palette;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const TrackTile({
    super.key,
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.isFavorite,
    required this.palette,
    required this.isDark,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final primaryAccent = AppColors.primaryColor(widget.palette);
    final track = widget.track;
    final isDark = widget.isDark;
    final isCurrent = widget.isCurrent;
    final isPlaying = widget.isPlaying;
    final isFavorite = widget.isFavorite;

    // [WIDGET PURPOSE]: GestureDetector
    // [LAYOUT PROBLEM SOLVED]: Captures taps on the track tile with interactive pop-in / pop-out spring feedback.
    // [BEHAVIOR & CONSTRAINTS]: Bounds touch events strictly within the card rectangle.
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      // [WIDGET PURPOSE]: AnimatedScale
      // [LAYOUT PROBLEM SOLVED]: Smooth micro-spring pop animation when user touches or releases a song.
      // [BEHAVIOR & CONSTRAINTS]: Scales to 0.975 when pressed, rebounds to 1.0.
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: AppDecorations.glassCard3D(
            context: context,
            palette: widget.palette,
            isDark: isDark,
            borderRadius: 20.0,
            isHovered: isCurrent,
          ),
          // [WIDGET PURPOSE]: Row
          // [LAYOUT PROBLEM SOLVED]: Arranges album artwork, metadata text, and action buttons in a horizontal row.
          // [BEHAVIOR & CONSTRAINTS]: Positions children along the main axis with crossAxisAlignment center.
          child: Row(
            children: [
              // Album Artwork with 3D Rounded Border
              ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      track.artworkUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: track.artworkUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _buildPlaceholder(),
                              placeholder: (context, url) => Container(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            )
                          : _buildPlaceholder(),

                      // Animated Equalizer Overlay when active
                      if (isCurrent)
                        Container(
                          color: Colors.black.withOpacity(0.45),
                          child: Center(
                            child: Icon(
                              isPlaying
                                  ? Icons.graphic_eq_rounded
                                  : Icons.play_arrow_rounded,
                              color: primaryAccent,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Metadata Column (Title, Artist, Badge)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Track Title
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent
                            ? primaryAccent
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Artist & Genre Row
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${track.formattedDuration}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Badges Wrap: Provider Source & Playback Capability
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Provider badge (JioSaavn, Jamendo, Audius, iTunes)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: track.provider == 'jiosaavn'
                                ? Colors.cyan.withOpacity(0.18)
                                : track.provider == 'audius'
                                    ? const Color(0xFFCC00FF).withOpacity(0.18)
                                    : track.provider == 'jamendo'
                                        ? const Color(0xFFFF6600).withOpacity(0.18)
                                        : Colors.blueAccent.withOpacity(0.18),
                          ),
                          child: Text(
                            track.provider.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: track.provider == 'jiosaavn'
                                  ? Colors.cyanAccent
                                  : track.provider == 'audius'
                                      ? const Color(0xFFCC00FF)
                                      : track.provider == 'jamendo'
                                          ? const Color(0xFFFF6600)
                                          : Colors.blueAccent,
                            ),
                          ),
                        ),

                        // Capability Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: track.capability == PlaybackCapability.authorizedFullStream
                                ? AppColors.mintAccent.withOpacity(0.16)
                                : primaryAccent.withOpacity(0.14),
                          ),
                          child: Text(
                            track.capability == PlaybackCapability.authorizedFullStream
                                ? 'FULL STREAM'
                                : 'PREVIEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                              color: track.capability == PlaybackCapability.authorizedFullStream
                                  ? AppColors.mintAccent
                                  : primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Trailing Actions (Add to Playlist & Favorite) with rapid bounce back
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InteractiveBounceButton(
                    pressScale: 0.86,
                    onTap: () => _showAddToPlaylistSheet(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.playlist_add_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InteractiveBounceButton(
                    pressScale: 0.86,
                    onTap: widget.onFavoriteToggle,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? const Color(0xFFFF3366)
                            : (isDark ? Colors.white38 : Colors.black38),
                        size: 21,
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

  void _showAddToPlaylistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor(widget.palette, widget.isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final musicState = context.read<MusicCubit>().state;
        final playlists = (musicState is MusicLoaded) ? musicState.playlists : <Playlist>[];
        final primaryAccent = AppColors.primaryColor(widget.palette);
        final track = widget.track;
        final isDark = widget.isDark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add to Playlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(height: 16),
                if (playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No playlists created yet. Create one in Library!',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final pl = playlists[index];
                        final alreadyAdded = pl.tracks.any((t) => t.id == track.id);
                        return InteractiveBounceButton(
                          pressScale: 0.96,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final musicCubit = context.read<MusicCubit>();
                            Navigator.pop(ctx);
                            if (alreadyAdded) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Already in "${pl.name}"')),
                              );
                            } else {
                              await musicCubit.addTrackToPlaylist(pl.id, track);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Added "${track.title}" to "${pl.name}"'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: AppColors.primaryGradient(widget.palette),
                              ),
                              child: const Icon(Icons.queue_music_rounded, color: Colors.black, size: 20),
                            ),
                            title: Text(pl.name),
                            subtitle: Text('${pl.tracks.length} tracks'),
                            trailing: alreadyAdded
                                ? Icon(Icons.check_circle_rounded, color: primaryAccent, size: 22)
                                : const Icon(Icons.add_circle_outline_rounded, size: 22),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: widget.isDark ? const Color(0xFF1E2438) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: widget.isDark ? Colors.white30 : Colors.black26,
          size: 28,
        ),
      ),
    );
  }
}
