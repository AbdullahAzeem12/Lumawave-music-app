import 'package:flutter/material.dart';

/// A premium, hardware-accelerated micro-spring rapid bounce button.
/// On touch or click, it rapidly depresses (compresses) and snaps back
/// with an elastic overshoot bounce, while executing callbacks immediately
/// with zero input delay.
class InteractiveBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final Duration pressDuration;
  final Duration bounceDuration;
  final HitTestBehavior behavior;

  const InteractiveBounceButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.925,
    this.pressDuration = const Duration(milliseconds: 55),
    this.bounceDuration = const Duration(milliseconds: 130),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<InteractiveBounceButton> createState() => _InteractiveBounceButtonState();
}

class _InteractiveBounceButtonState extends State<InteractiveBounceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHeldDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.bounceDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _isHeldDown = true;
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _isHeldDown = false;
    _controller.reverse();
  }

  void _onTapCancel() {
    _isHeldDown = false;
    _controller.reverse();
  }

  void _onTap() {
    if (widget.onTap == null) return;
    // Execute callback immediately for rapid response
    widget.onTap!();

    // Trigger rapid bounce back if not currently held
    if (!_isHeldDown) {
      _controller.forward().then((_) {
        if (mounted) {
          _controller.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap != null ? _onTap : null,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.center,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
