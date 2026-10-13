import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../cubit/player_cubit.dart';
import '../cubit/music_cubit.dart';
import '../../services/audio_player_service.dart';
import '../../../../core/widgets/interactive_bounce_button.dart';
import 'lyrics_view.dart';

class ExpandedPlayerScreen extends StatefulWidget {
  const ExpandedPlayerScreen({super.key});

  @override
  State<ExpandedPlayerScreen> createState() => _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends State<ExpandedPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _showLyrics = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);
    final secondaryAccent = AppColors.secondaryColor(palette);

    final playerState = context.watch<PlayerCubit>().state;
    final track = playerState.currentTrack;

    if (playerState.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor(palette, isDark),
        body: const Center(child: Text('No song currently playing')),
      );
    }

    final isFav = context.watch<MusicCubit>().isFavorite(track.id);

    // [WIDGET PURPOSE]: Scaffold
    // [LAYOUT PROBLEM SOLVED]: Manages root full-screen canvas for the expanded 3D player.
    // [BEHAVIOR & CONSTRAINTS]: Imposes bounds and background theme coloring.
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(palette, isDark),
      // [WIDGET PURPOSE]: Stack
      // [LAYOUT PROBLEM SOLVED]: Layers ambient radial glow backdrops behind album art and player controls.
      // [BEHAVIOR & CONSTRAINTS]: Allows unconstrained composite overlapping.
      body: Stack(
        children: [
          // Ambient Glow Emitters
          Positioned(
            top: -60,
            left: -60,
            child: AppDecorations.ambientGlowOrb(
              color: primaryAccent,
              size: 340,
              opacity: 0.35,
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: AppDecorations.ambientGlowOrb(
              color: secondaryAccent,
              size: 340,
              opacity: 0.30,
            ),
          ),

          // [WIDGET PURPOSE]: SafeArea
          // [LAYOUT PROBLEM SOLVED]: Keeps controls and lyrics outside hardware notches and gesture bars.
          // [BEHAVIOR & CONSTRAINTS]: Applies device window padding.
          SafeArea(
            // [WIDGET PURPOSE]: Column
            // [LAYOUT PROBLEM SOLVED]: Positions top bar, artwork/lyrics switcher, seek bar, and control buttons vertically.
            // [BEHAVIOR & CONSTRAINTS]: Fits screen height.
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  // [WIDGET PURPOSE]: Row
                  // [LAYOUT PROBLEM SOLVED]: Spaces out dismiss chevron, "NOW PLAYING" header, and favorite button.
                  // [BEHAVIOR & CONSTRAINTS]: Aligns children horizontally.
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.album.isNotEmpty ? track.album : track.genre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFFF3366) : (isDark ? Colors.white70 : Colors.black54),
                          size: 26,
                        ),
                        onPressed: () {
                          context.read<MusicCubit>().toggleFavorite(track);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Center Content: Either 3D Rotating Artwork OR Synchronized Lyrics View
                // [WIDGET PURPOSE]: Expanded
                // [LAYOUT PROBLEM SOLVED]: Allows artwork or lyrics to occupy all dynamic vertical space between top and bottom bars.
                // [BEHAVIOR & CONSTRAINTS]: Flex 1 distribution.
                Expanded(
                  child: _showLyrics
                      ? LyricsView(
                          playerState: playerState,
                          palette: palette,
                          isDark: isDark,
                          onSeek: (pos) => context.read<PlayerCubit>().seek(pos),
                        )
                      : Center(
                          // [WIDGET PURPOSE]: AnimatedBuilder
                          // [LAYOUT PROBLEM SOLVED]: Rotates the vinyl album cover 360 degrees when playing without rebuilding the whole tree.
                          // [BEHAVIOR & CONSTRAINTS]: Repaints only the spinning transform on tick.
                          child: AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateZ(_rotationController.value * 2 * math.pi),
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryAccent.withOpacity(0.5),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryAccent.withOpacity(0.4),
                                        blurRadius: 36,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: track.artworkUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: track.artworkUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: isDark ? Colors.white10 : Colors.black12,
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.black26,
                                              child: const Icon(Icons.music_note, size: 60),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.black26,
                                            child: const Icon(Icons.music_note, size: 60),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Mode Switcher: Cover Art vs. Synced Lyrics Button
                Center(
                  child: InteractiveBounceButton(
                    pressScale: 0.92,
                    onTap: () {
                      setState(() {
                        _showLyrics = !_showLyrics;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        border: Border.all(
                          color: _showLyrics ? primaryAccent : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showLyrics ? Icons.album_rounded : Icons.lyrics_rounded,
                            size: 18,
                            color: _showLyrics ? primaryAccent : (isDark ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showLyrics ? 'SHOW COVER' : 'LIVE LYRICS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: _showLyrics ? primaryAccent : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Track Title & Artist Metadata
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Progress Slider & Timestamps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Slider(
                        value: playerState.progress,
                        activeColor: primaryAccent,
                        inactiveColor: isDark ? Colors.white12 : Colors.black12,
                        onChanged: (val) {
                          final targetMs = (val * playerState.duration.inMilliseconds).toInt();
                          context.read<PlayerCubit>().seek(Duration(milliseconds: targetMs));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              playerState.positionFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                            Text(
                              playerState.durationFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Main Playback Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle Button with rapid bounce back
                      InteractiveBounceButton(
                        pressScale: 0.88,
                        onTap: () => context.read<PlayerCubit>().toggleShuffle(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.shuffle_rounded,
                            color: playerState.isShuffle
                                ? primaryAccent
                                : (isDark ? Colors.white38 : Colors.black38),
                            size: 26,
                          ),
                        ),
                      ),

                      // Previous Track Button with rapid bounce back
                      InteractiveBounceButton(
                        pressScale: 0.88,
                        onTap: () => context.read<PlayerCubit>().previous(),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.skip_previous_rounded,
                            color: isDark ? Colors.white : Colors.black,
                            size: 38,
                          ),
                        ),
                      ),

                      // Central 3D Play/Pause Button with rapid bounce back
                      InteractiveBounceButton(
                        pressScale: 0.90,
                        onTap: () => context.read<PlayerCubit>().togglePlayPause(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: AppDecorations.primary3DButton(
                            palette: palette,
                            borderRadius: 999,
                          ),
                          child: Icon(
                            playerState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // Next Track Button with rapid bounce back
                      InteractiveBounceButton(
                        pressScale: 0.88,
                        onTap: () => context.read<PlayerCubit>().next(),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.skip_next_rounded,
                            color: isDark ? Colors.white : Colors.black,
                            size: 38,
                          ),
                        ),
                      ),

                      // Repeat Mode Button with rapid bounce back
                      InteractiveBounceButton(
                        pressScale: 0.88,
                        onTap: () => context.read<PlayerCubit>().toggleRepeat(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            playerState.repeatMode == PlaybackRepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: playerState.repeatMode != PlaybackRepeatMode.off
                                ? primaryAccent
                                : (isDark ? Colors.white38 : Colors.black38),
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
