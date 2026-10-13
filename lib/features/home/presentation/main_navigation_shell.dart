import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../../music/presentation/widgets/mini_player.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../core/widgets/interactive_bounce_button.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial and periodic check for email confirmation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus();
      // Periodically check every 6 seconds if user is unverified so confirmation is instantly detected
      _periodicCheckTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        final authState = context.read<AuthCubit>().state;
        if (authState is Authenticated && !authState.user.isEmailVerified) {
          _checkVerificationStatus();
        } else {
          _periodicCheckTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from Gmail / browser, immediately check confirmation status!
    if (state == AppLifecycleState.resumed) {
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus({
    bool showNotificationIfSuccess = true,
    bool showPendingNotice = false,
  }) async {
    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;

    if (authState is Authenticated && !authState.user.isEmailVerified) {
      final confirmed = await authCubit.checkEmailConfirmationStatus();
      if (!mounted) return;

      if (confirmed) {
        _periodicCheckTimer?.cancel();
        if (showNotificationIfSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.black, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your email has been confirmed successfully! Welcome to Pulse.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (showPendingNotice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification still pending in Supabase. Please tap the link in your email or enter the OTP code.',
              style: TextStyle(fontSize: 12),
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showOtpDialog(String email) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
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
                color: primaryAccent.withOpacity(0.35),
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient(palette),
                        boxShadow: [
                          BoxShadow(
                            color: primaryAccent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.pin_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONFIRM EMAIL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verification Code',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the 6-digit confirmation code sent to $email:',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '123456',
                    hintStyle: TextStyle(
                      letterSpacing: 4,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                        pressScale: 0.94,
                        onTap: () => Navigator.pop(dialogCtx),
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
                        onTap: () async {
                          final code = otpController.text.trim();
                          if (code.isNotEmpty) {
                            Navigator.pop(dialogCtx);
                            await context.read<AuthCubit>().verifyEmailOtp(email, code);
                            _checkVerificationStatus(showNotificationIfSuccess: true);
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
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Confirm',
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
    final authState = context.watch<AuthCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);
    final secondaryAccent = AppColors.secondaryColor(palette);

    final isUnconfirmed =
        authState is Authenticated && !authState.user.isEmailVerified;
    final userEmail = (authState is Authenticated) ? authState.user.email : '';

    final pages = [
      HomeScreen(onNavigateToSearch: () => setState(() => _currentIndex = 2)),
      DiscoverScreen(onNavigateToHome: () => setState(() => _currentIndex = 0)),
      const SearchScreen(),
      const LibraryScreen(),
      const SettingsScreen(),
    ];

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
              size: 320,
              opacity: 0.30,
            ),
          ),

          // Active Page View
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),

          // ─── Floating In-App Verification Banner (Only if unconfirmed) ───
          if (isUnconfirmed)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        primaryAccent.withOpacity(0.92),
                        secondaryAccent.withOpacity(0.92),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAccent.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_rounded,
                          size: 18, color: Colors.black),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Email confirmation pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // "I've Confirmed" Button
                      InkWell(
                        onTap: () => _checkVerificationStatus(
                          showNotificationIfSuccess: true,
                          showPendingNotice: true,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "I've Confirmed",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // "Enter Code" Button
                      InkWell(
                        onTap: () => _showOtpDialog(userEmail),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Persistent Mini-Player Dock
          const Positioned(
            left: 0,
            right: 0,
            bottom: 74,
            child: MiniPlayer(),
          ),

          // 3D Glass Bottom Navigation Bar Dock
          Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: Container(
              height: 62,
              decoration: AppDecorations.glassDock(
                context: context,
                palette: palette,
                isDark: isDark,
                borderRadius: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home', primaryAccent, isDark),
                  _buildNavItem(1, Icons.explore_rounded, 'Discover', primaryAccent, isDark),
                  _buildNavItem(2, Icons.search_rounded, 'Search', primaryAccent, isDark),
                  _buildNavItem(3, Icons.library_music_rounded, 'Library', primaryAccent, isDark),
                  _buildNavItem(4, Icons.settings_rounded, 'Settings', primaryAccent, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;

    return InteractiveBounceButton(
      pressScale: 0.88,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? activeColor.withOpacity(isDark ? 0.2 : 0.15) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : (isDark ? Colors.white60 : Colors.black45),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : (isDark ? Colors.white60 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
