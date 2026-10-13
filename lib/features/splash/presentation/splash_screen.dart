import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../../auth/presentation/sign_in_screen.dart';
import '../../home/presentation/main_navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered animation intervals across the 7.0 second timeline
  late Animation<double> _ambientFade;
  late Animation<double> _orbScale;
  late Animation<double> _orbRotation;
  late Animation<double> _specularSweep;
  late Animation<double> _titleFade;
  late Animation<double> _titleSpacing;
  late Animation<double> _exitScale;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // 7.0-second total master choreography controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    // 0.0s - 0.7s: Ambient background reveal
    _ambientFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.10, curve: Curves.easeOut),
    );

    // 0.7s - 2.0s: 3D Orb entrance with elastic overshoot
    _orbScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.30, curve: Curves.elasticOut),
    );

    // 0.7s - 2.0s: 3D perspective rotation on Y-axis
    _orbRotation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    // 2.0s - 3.5s: Specular sweep highlight across the glass surface
    _specularSweep = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.50, curve: Curves.easeInOutCubic),
      ),
    );

    // 3.5s - 5.5s: Title fade and letter-spacing parallax reveal
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.75, curve: Curves.easeIn),
    );

    _titleSpacing = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    // 5.5s - 7.0s: Cinematic exit dissolve into the application
    _exitScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) => _navigateToNextScreen());
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final authState = context.read<AuthCubit>().state;
    final destination = (authState is Authenticated)
        ? const MainNavigationShell()
        : const SignInScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildWaveBar(double height, Color color) {
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);
    final secondaryAccent = AppColors.secondaryColor(palette);

    // [WIDGET PURPOSE]: Scaffold
    // [LAYOUT PROBLEM SOLVED]: Provides the root visual framework and manages system insets.
    // [BEHAVIOR & CONSTRAINTS]: Imposes full-screen bounds on all descendant layout trees.
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(palette, isDark),
      // [WIDGET PURPOSE]: Stack
      // [LAYOUT PROBLEM SOLVED]: Layers ambient radial glow meshes behind the 3D logo and brand typography.
      // [BEHAVIOR & CONSTRAINTS]: Allows overlapping non-positioned and positioned composite elements.
      body: Stack(
        children: [
          // Ambient Neon Glow Mesh (Top-Left)
          // [WIDGET PURPOSE]: Positioned
          // [LAYOUT PROBLEM SOLVED]: Pinpoints the top-left ambient light emitter at fixed screen coordinates.
          // [BEHAVIOR & CONSTRAINTS]: Resolves exact offsets from the parent Stack's top and left boundaries.
          Positioned(
            top: -60,
            left: -60,
            // [WIDGET PURPOSE]: FadeTransition
            // [LAYOUT PROBLEM SOLVED]: Animates the ambient glow intensity over time without rebuild overhead.
            // [BEHAVIOR & CONSTRAINTS]: Modifies the visual alpha channel directly at the render layer.
            child: FadeTransition(
              opacity: _ambientFade,
              child: AppDecorations.ambientGlowOrb(
                color: primaryAccent,
                size: 320,
                opacity: 0.45,
              ),
            ),
          ),

          // Ambient Neon Glow Mesh (Bottom-Right)
          Positioned(
            bottom: -60,
            right: -60,
            child: FadeTransition(
              opacity: _ambientFade,
              child: AppDecorations.ambientGlowOrb(
                color: secondaryAccent,
                size: 340,
                opacity: 0.35,
              ),
            ),
          ),

          // Central 3D Shiny Emblem & Typography
          // [WIDGET PURPOSE]: Center
          // [LAYOUT PROBLEM SOLVED]: Perfectly aligns the central 3D brand assembly in both horizontal and vertical axes.
          // [BEHAVIOR & CONSTRAINTS]: Takes all available parent room and places its child at (0, 0) relative center.
          Center(
            // [WIDGET PURPOSE]: AnimatedBuilder
            // [LAYOUT PROBLEM SOLVED]: Rebuilds only the 3D transforms on animation tick, isolating GPU performance.
            // [BEHAVIOR & CONSTRAINTS]: Listens to the master controller and updates the transformation matrix.
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _exitScale.value,
                  // [WIDGET PURPOSE]: Opacity
                  // [LAYOUT PROBLEM SOLVED]: Dissolves the entire central brand assembly during the 5.5s - 7.0s exit phase.
                  // [BEHAVIOR & CONSTRAINTS]: Modifies composite rendering alpha for the exit sequence.
                  child: Opacity(
                    opacity: _exitFade.value,
                    // [WIDGET PURPOSE]: Column
                    // [LAYOUT PROBLEM SOLVED]: Stacks the 3D sphere, the brand name, and the subtitle vertically with controlled spacing.
                    // [BEHAVIOR & CONSTRAINTS]: Shrink-wraps vertically using MainAxisSize.min to prevent unbounded expansion.
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3D Glass Sphere with Specular Highlight and Audio Waves
                        // [WIDGET PURPOSE]: Transform
                        // [LAYOUT PROBLEM SOLVED]: Applies Matrix4 perspective rotation to simulate a real-world volumetric 3D orb.
                        // [BEHAVIOR & CONSTRAINTS]: Injects 3D perspective depth at index (3, 2).
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateY(_orbRotation.value),
                          child: Transform.scale(
                            scale: _orbScale.value,
                            // [WIDGET PURPOSE]: Container
                            // [LAYOUT PROBLEM SOLVED]: Forms the physical boundary, circular shape, and specular borders of the orb.
                            // [BEHAVIOR & CONSTRAINTS]: Constrains width and height strictly to 160x160 pixels.
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.28),
                                    Colors.white.withOpacity(0.06),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.45),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(0.6),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: secondaryAccent.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: -4,
                                    offset: const Offset(0, -6),
                                  ),
                                ],
                              ),
                              // [WIDGET PURPOSE]: Stack
                              // [LAYOUT PROBLEM SOLVED]: Overlays the pulsating audio wave vectors and the sweeping specular shine within the orb.
                              // [BEHAVIOR & CONSTRAINTS]: Fits perfectly within the 160x160 circular container.
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Specular Sweep Beam
                                  Transform.translate(
                                    offset: Offset(_specularSweep.value * 60, _specularSweep.value * 40),
                                    child: Transform.rotate(
                                      angle: -math.pi / 4,
                                      child: Container(
                                        width: 180,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.45),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Central Audio Wave Pulse Symbol
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildWaveBar(24.0, primaryAccent),
                                      const SizedBox(width: 5),
                                      _buildWaveBar(44.0, primaryAccent),
                                      const SizedBox(width: 5),
                                      _buildWaveBar(64.0, Colors.white),
                                      const SizedBox(width: 5),
                                      _buildWaveBar(44.0, secondaryAccent),
                                      const SizedBox(width: 5),
                                      _buildWaveBar(24.0, secondaryAccent),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // [WIDGET PURPOSE]: SizedBox
                        // [LAYOUT PROBLEM SOLVED]: Enforces fixed vertical breathing room between the 3D orb and the brand title.
                        // [BEHAVIOR & CONSTRAINTS]: Rigid height constraint of 36 pixels.
                        const SizedBox(height: 36),

                        // Brand Title: LUMAWAVE
                        FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'LUMAWAVE',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: _titleSpacing.value,
                              color: primaryAccent,
                              shadows: [
                                Shadow(
                                  color: primaryAccent.withOpacity(0.8),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'YOUR SOUND • YOUR UNIVERSE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
