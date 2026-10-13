import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/player_state.dart';

class LyricsView extends StatefulWidget {
  final PlayerState playerState;
  final AppPalette palette;
  final bool isDark;
  final Function(Duration) onSeek;

  const LyricsView({
    super.key,
    required this.playerState,
    required this.palette,
    required this.isDark,
    required this.onSeek,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];
  int _lastAutoScrolledIndex = -1;

  void _syncKeys(int count) {
    while (_itemKeys.length < count) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentIndex = widget.playerState.activeLyricIndex;
    final lines = widget.playerState.lyrics.syncedLines;

    if (lines.isNotEmpty &&
        currentIndex != _lastAutoScrolledIndex &&
        currentIndex >= 0 &&
        currentIndex < lines.length) {
      _lastAutoScrolledIndex = currentIndex;
      _scrollToActiveLine(currentIndex);
    }
  }

  void _scrollToActiveLine(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (index >= 0 && index < _itemKeys.length) {
        final keyContext = _itemKeys[index].currentContext;
        if (keyContext != null) {
          Scrollable.ensureVisible(
            keyContext,
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeInOutCubic,
            alignment: 0.45,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.playerState.lyrics;
    final primaryAccent = AppColors.primaryColor(widget.palette);

    if (widget.playerState.isLoadingLyrics) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Fetching live synchronized lyrics...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    if (!lyrics.hasSynced && lyrics.plainText.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 52,
              color: widget.isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No lyrics found for this track',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enjoy the pure instrumentation!',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    // Synced Lyrics List with moving transition highlighting
    if (lyrics.hasSynced) {
      final lines = lyrics.syncedLines;
      _syncKeys(lines.length);
      final activeIndex = widget.playerState.activeLyricIndex;

      // [WIDGET PURPOSE]: ShaderMask
      // [LAYOUT PROBLEM SOLVED]: Smoothly fades the top and bottom edges of the lyrics viewport for a premium Spotify/Apple Music appearance.
      // [BEHAVIOR & CONSTRAINTS]: Applies vertical fade gradient.
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.08, 0.92, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        // [WIDGET PURPOSE]: ListView.builder
        // [LAYOUT PROBLEM SOLVED]: Efficiently scrolls and renders only visible synchronized lyric lines.
        // [BEHAVIOR & CONSTRAINTS]: Full scroll extent with bouncy spring physics.
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final line = lines[index];
            final isActive = index == activeIndex;
            final diff = (index - activeIndex).abs();

            final double opacity = isActive ? 1.0 : (diff == 1 ? 0.65 : 0.35);
            final double scale = isActive ? 1.05 : 0.98;
            final double fontSize = isActive ? 21.0 : (diff == 1 ? 16.5 : 15.0);
            final FontWeight fontWeight =
                isActive ? FontWeight.w800 : (diff == 1 ? FontWeight.w600 : FontWeight.w500);

            // [WIDGET PURPOSE]: GestureDetector
            // [LAYOUT PROBLEM SOLVED]: Enables tap-to-seek directly to any lyric line.
            // [BEHAVIOR & CONSTRAINTS]: Triggers seek on tap.
            return GestureDetector(
              key: _itemKeys[index],
              onTap: () {
                widget.onSeek(Duration(milliseconds: line.timestampMs));
              },
              // [WIDGET PURPOSE]: AnimatedScale
              // [LAYOUT PROBLEM SOLVED]: Dynamically enlarges the active lyric line with high-frame-rate spring easing.
              // [BEHAVIOR & CONSTRAINTS]: Scales up active line to 1.05x smoothly.
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                // [WIDGET PURPOSE]: AnimatedOpacity
                // [LAYOUT PROBLEM SOLVED]: Fades distant lines into background while highlighting the current line.
                // [BEHAVIOR & CONSTRAINTS]: Animate opacity between 0.35 and 1.0.
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  // [WIDGET PURPOSE]: AnimatedContainer
                  // [LAYOUT PROBLEM SOLVED]: Applies moving glowing backdrop and capsule highlight to active line.
                  // [BEHAVIOR & CONSTRAINTS]: Changes padding, background color, gradient, and glow border.
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: isActive ? 14.0 : 8.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: isActive
                          ? LinearGradient(
                              colors: [
                                primaryAccent.withOpacity(widget.isDark ? 0.22 : 0.15),
                                primaryAccent.withOpacity(widget.isDark ? 0.08 : 0.04),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      border: isActive
                          ? Border.all(
                              color: primaryAccent.withOpacity(0.55),
                              width: 1.5,
                            )
                          : Border.all(color: Colors.transparent, width: 1.5),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: primaryAccent.withOpacity(0.25),
                                blurRadius: 18,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    // [WIDGET PURPOSE]: Text
                    // [LAYOUT PROBLEM SOLVED]: Renders the lyric line with animated typography and neon glow.
                    // [BEHAVIOR & CONSTRAINTS]: Centered text with multi-layer shadow glow.
                    child: Text(
                      line.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        letterSpacing: isActive ? 0.2 : 0.0,
                        height: 1.35,
                        color: isActive
                            ? (widget.isDark ? Colors.white : primaryAccent)
                            : (widget.isDark ? Colors.white70 : Colors.black87),
                        shadows: isActive
                            ? [
                                Shadow(
                                  color: primaryAccent.withOpacity(0.85),
                                  blurRadius: 18,
                                ),
                                Shadow(
                                  color: primaryAccent.withOpacity(0.4),
                                  blurRadius: 36,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Plain Text Lyrics Fallback
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Text(
        lyrics.plainText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          height: 1.8,
          color: widget.isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
