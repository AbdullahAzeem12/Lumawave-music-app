import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium, high-performance smooth scroller wrapper with interactive glowing scrollbar
class PulseSmoothScroller extends StatelessWidget {
  final Widget child;
  final ScrollController controller;
  final AppPalette palette;
  final bool isDark;
  final double thickness;
  final EdgeInsets padding;

  const PulseSmoothScroller({
    super.key,
    required this.child,
    required this.controller,
    required this.palette,
    required this.isDark,
    this.thickness = 5.0,
    this.padding = const EdgeInsets.only(right: 2.0, top: 6.0, bottom: 6.0),
  });

  @override
  Widget build(BuildContext context) {
    final primaryAccent = AppColors.primaryColor(palette);

    return RawScrollbar(
      controller: controller,
      thumbColor: primaryAccent.withOpacity(isDark ? 0.85 : 0.70),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      thickness: thickness,
      minThumbLength: 48.0,
      interactive: true,
      fadeDuration: const Duration(milliseconds: 300),
      timeToFade: const Duration(milliseconds: 1400),
      padding: padding,
      child: child,
    );
  }
}

/// Pop-in, pop-out & fade-in transition for smooth list scrolling without dropping frames
class SmoothSongTransition extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const SmoothSongTransition({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 360),
  });

  @override
  State<SmoothSongTransition> createState() => _SmoothSongTransitionState();
}

class _SmoothSongTransitionState extends State<SmoothSongTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Stagger delay for initial viewport elements capped at 220ms
    final delayMs = (widget.index.clamp(0, 6) * 32);
    if (delayMs > 0) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
