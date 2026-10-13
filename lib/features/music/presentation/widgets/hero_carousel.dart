import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/interactive_bounce_button.dart';
import '../../domain/track.dart';

class HeroCarousel extends StatefulWidget {
  final List<Track> tracks;
  final AppPalette palette;
  final bool isDark;
  final Function(Track) onPlayTrack;

  const HeroCarousel({
    super.key,
    required this.tracks,
    required this.palette,
    required this.isDark,
    required this.onPlayTrack,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86, initialPage: 0);
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tracks.isEmpty) return const SizedBox.shrink();

    final primaryAccent = AppColors.primaryColor(widget.palette);
    final count = widget.tracks.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Smooth Slider Bar
        // [WIDGET PURPOSE]: Container
        // [LAYOUT PROBLEM SOLVED]: Displays active index badge and smooth glowing slider track.
        // [BEHAVIOR & CONSTRAINTS]: Horizontal padding 22px, height 28px.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Active Index Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: primaryAccent.withOpacity(widget.isDark ? 0.16 : 0.10),
                  border: Border.all(
                    color: primaryAccent.withOpacity(0.35),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'FEATURED ${(_currentPage.round() + 1).clamp(1, count)} / $count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: primaryAccent,
                  ),
                ),
              ),

              // Smooth Glowing Slider Track
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  const trackWidth = 130.0;
                  final fraction = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                  final targetPage = (fraction * (count - 1)).round();
                  _pageController.animateToPage(
                    targetPage,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Container(
                  width: 130.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                  ),
                  child: Stack(
                    children: [
                      // Animated Indicator Thumb
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final thumbWidth = (constraints.maxWidth / count).clamp(24.0, 48.0);
                          final maxLeft = constraints.maxWidth - thumbWidth;
                          final progress = count > 1 ? (_currentPage / (count - 1)).clamp(0.0, 1.0) : 0.0;
                          final leftOffset = progress * maxLeft;

                          return Positioned(
                            left: leftOffset,
                            top: 0,
                            bottom: 0,
                            width: thumbWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: AppColors.primaryGradient(widget.palette),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(0.6),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Hero 3D Cards with Pop-in / Pop-out and Fade-in / Fade-out Transition
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: count,
            itemBuilder: (context, index) {
              final track = widget.tracks[index];

              // Smooth fractional delta from current center
              final diff = (index - _currentPage).abs();
              final scale = (1.0 - (diff * 0.12)).clamp(0.86, 1.0);
              final opacity = (1.0 - (diff * 0.38)).clamp(0.55, 1.0);

              // [WIDGET PURPOSE]: Transform.scale
              // [LAYOUT PROBLEM SOLVED]: Pop-in and pop-out scale transition as cards slide in/out of center.
              // [BEHAVIOR & CONSTRAINTS]: Dynamic scale interpolation with 60/120fps hardware acceleration.
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: InteractiveBounceButton(
                    pressScale: 0.96,
                    onTap: () => widget.onPlayTrack(track),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26.0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Cover Image
                            if (track.artworkUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: track.artworkUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: widget.isDark ? Colors.white10 : Colors.black12,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: widget.isDark ? Colors.white12 : Colors.black26,
                                ),
                              )
                            else
                              Container(color: Colors.black45),

                            // Atmospheric Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.35),
                                    Colors.black.withOpacity(0.92),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),

                            // Hot Release Badge
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.black.withOpacity(0.6),
                                  border: Border.all(
                                    color: primaryAccent.withOpacity(0.6),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 14, color: primaryAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'HOT RELEASE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Content & Play Button
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          track.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${track.artist} • ${track.genre}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient(widget.palette),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryAccent.withOpacity(0.6),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
