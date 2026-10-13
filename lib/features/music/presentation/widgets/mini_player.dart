import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/interactive_bounce_button.dart';
import '../cubit/player_cubit.dart';
import '../player/expanded_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);

    final playerState = context.watch<PlayerCubit>().state;
    final track = playerState.currentTrack;

    if (track == null) return const SizedBox.shrink();

    // [WIDGET PURPOSE]: GestureDetector
    // [LAYOUT PROBLEM SOLVED]: Catches taps to launch the full-screen 3D Expanded Player modal.
    // [BEHAVIOR & CONSTRAINTS]: Bounds touch events to the dock container.
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ExpandedPlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              final tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      // [WIDGET PURPOSE]: Container
      // [LAYOUT PROBLEM SOLVED]: Creates the floating 3D glass dock container above bottom navigation.
      // [BEHAVIOR & CONSTRAINTS]: Imposes margins, height 68px, and glass dock styling.
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        height: 68,
        decoration: AppDecorations.glassDock(
          context: context,
          palette: palette,
          isDark: isDark,
          borderRadius: 22.0,
        ),
        // [WIDGET PURPOSE]: ClipRRect
        // [LAYOUT PROBLEM SOLVED]: Clips the live progress scrub bar directly to the dock's rounded corners.
        // [BEHAVIOR & CONSTRAINTS]: Radius 22px matching the container.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.0),
          // [WIDGET PURPOSE]: Stack
          // [LAYOUT PROBLEM SOLVED]: Overlays live playback progress line along top edge of mini player.
          // [BEHAVIOR & CONSTRAINTS]: Fits composite children across 68px height.
          child: Stack(
            children: [
              // Live Progress Scrub Bar along Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: playerState.progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  minHeight: 2.5,
                ),
              ),

              // Mini Player Controls Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    // Album Artwork Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: track.artworkUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.artworkUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.black26),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.black26,
                                  child: const Icon(Icons.music_note, size: 24),
                                ),
                              )
                            : Container(
                                color: Colors.black26,
                                child: const Icon(Icons.music_note, size: 24),
                              ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Song Title & Artist Text
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Play/Pause Button with rapid bounce back
                    InteractiveBounceButton(
                      pressScale: 0.88,
                      onTap: () => context.read<PlayerCubit>().togglePlayPause(),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          playerState.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: primaryAccent,
                          size: 38,
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
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
