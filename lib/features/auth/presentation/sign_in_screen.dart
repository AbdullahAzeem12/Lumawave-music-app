import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../auth/data/auth_repository.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_state.dart';
import 'register_screen.dart';
import '../../home/presentation/main_navigation_shell.dart';
import '../../../core/widgets/interactive_bounce_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isAutofilled = false;
  Map<String, String> _savedAccounts = {};

  // ─── Animation Controllers ───
  late final AnimationController _entranceController;
  late final AnimationController _logoPulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _buttonGlowController;
  late final AnimationController _cardShimmerController;

  // ─── Entrance Animations (staggered) ───
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _headingSlide;
  late final Animation<double> _headingOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _formOpacity;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();

    // ─── Credentials Auto-detection Listeners ───
    _emailController.addListener(_onEmailChanged);

    // ─── Initialize Remembered Credentials from Database ───
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberedCredentials();
    });

    // ─── Entrance Controller (staggered cascade) ───
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Card: scale from 0.85 → 1.0 with opacity
    _cardScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Logo: scale bounce + fade
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.50, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.40, curve: Curves.easeOut),
      ),
    );

    // Heading: slide up + fade
    _headingSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _headingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.50, curve: Curves.easeOut),
      ),
    );

    // Subtitle: slide up + fade
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.55, curve: Curves.easeOut),
      ),
    );

    // Form fields: slide up + fade
    _formSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.65, curve: Curves.easeOut),
      ),
    );

    // Buttons: slide up + fade
    _buttonSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.80, curve: Curves.easeOutCubic),
      ),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.75, curve: Curves.easeOut),
      ),
    );

    // Footer
    _footerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
      ),
    );

    // ─── Logo Pulse (infinite breathing) ───
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // ─── Heading Shimmer (infinite gradient sweep) ───
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // ─── Button Glow Pulse (infinite) ───
    _buttonGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // ─── Card Border Shimmer (infinite) ───
    _cardShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Start entrance
    _entranceController.forward();
  }

  /// Loads remembered accounts from persistent database and automatically auto-fills credentials
  Future<void> _loadRememberedCredentials() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final authCubit = context.read<AuthCubit>();
      final accounts = await authRepo.getAllSavedAccounts();
      if (!mounted) return;
      setState(() {
        _savedAccounts = accounts;
      });

      // Check auth state for remembered credentials
      final authState = authCubit.state;
      String? emailToFill;
      String? passToFill;

      if (authState is Unauthenticated) {
        emailToFill = authState.rememberedEmail;
        passToFill = authState.rememberedPassword;
      }

      emailToFill ??= await authRepo.getRememberedEmail();
      if (emailToFill != null && emailToFill.isNotEmpty) {
        if (_emailController.text.isEmpty) {
          _emailController.text = emailToFill;
        }
        passToFill ??= await authRepo.getSavedPasswordForEmail(emailToFill);
      }

      // If credentials found in database, auto-fill password immediately!
      if (passToFill != null && passToFill.isNotEmpty) {
        _passwordController.text = passToFill;
        if (mounted) {
          setState(() {
            _isAutofilled = true;
            _rememberMe = true;
          });
        }
      }
    } catch (_) {}
  }

  /// Immediately detects email from database when user types/changes email, and auto-fills password
  void _onEmailChanged() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      if (_isAutofilled) {
        setState(() {
          _isAutofilled = false;
        });
      }
      return;
    }

    try {
      final authRepo = context.read<AuthRepository>();
      final savedPass = await authRepo.getSavedPasswordForEmail(email);

      if (savedPass != null && savedPass.isNotEmpty) {
        if (_passwordController.text != savedPass) {
          _passwordController.text = savedPass;
        }
        if (!_isAutofilled || !_rememberMe) {
          if (mounted) {
            setState(() {
              _isAutofilled = true;
              _rememberMe = true;
            });
          }
        }
      } else {
        if (_isAutofilled) {
          if (mounted) {
            setState(() {
              _isAutofilled = false;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _logoPulseController.dispose();
    _shimmerController.dispose();
    _buttonGlowController.dispose();
    _cardShimmerController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
    }
  }

  /// Displays dialog to resolve unconfirmed email with options to enter directly or resend link
  void _showEmailNotConfirmedDialog(String email) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = context.read<ThemeCubit>().state.isDark;
        final palette = context.read<ThemeCubit>().state.palette;
        final primaryAccent = AppColors.primaryColor(palette);
        final cleanEmail = email.isNotEmpty ? email : _emailController.text.trim();

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
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCOUNT VERIFICATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Email Confirmation',
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
                  'Your credentials for $cleanEmail are valid, but email verification is pending.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.success, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You can access the app immediately or resend the verification link.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InteractiveBounceButton(
                        pressScale: 0.94,
                        onTap: () {
                          context.read<AuthCubit>().resendConfirmationEmail(cleanEmail);
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Verification link resent to $cleanEmail'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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
                              'Resend Email',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InteractiveBounceButton(
                        pressScale: 0.94,
                        onTap: () {
                          Navigator.pop(dialogCtx);
                          context.read<AuthCubit>().enterWithUnconfirmedEmail(cleanEmail);
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
                              'Enter Pulse',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
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
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
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
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCOUNT SECURITY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reset Password',
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
                  'Enter your registered email address to receive password recovery instructions.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        onTap: () {
                          final email = resetController.text.trim();
                          if (email.isNotEmpty) {
                            context.read<AuthCubit>().sendPasswordReset(email);
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Password reset link sent to $email'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                              'Send Link',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);
    final secondaryAccent = AppColors.secondaryColor(palette);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // If email is not yet confirmed, notify user with friendly non-blocking notice
          if (!state.user.isEmailVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.mark_email_read_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Logged in as ${state.user.displayName}! Verification link sent to ${state.user.email}.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: primaryAccent.withOpacity(0.9),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Resend',
                  textColor: Colors.black,
                  onPressed: () {
                    context.read<AuthCubit>().resendConfirmationEmail(state.user.email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Verification link resent to ${state.user.email}'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            );
          }

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigationShell(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        } else if (state is AuthError) {
          if (state.message.toLowerCase().contains('email not confirmed')) {
            _showEmailNotConfirmedDialog(_emailController.text.trim());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor(palette, isDark),
        body: Stack(
          children: [
            // ─── Animated Ambient Top Glow ───
            AnimatedBuilder(
              animation: _cardShimmerController,
              builder: (context, child) {
                final pulse =
                    0.35 + 0.10 * math.sin(_cardShimmerController.value * math.pi * 2);
                return Positioned(
                  top: -80,
                  right: -80,
                  child: AppDecorations.ambientGlowOrb(
                    color: primaryAccent,
                    size: 340,
                    opacity: pulse,
                  ),
                );
              },
            ),

            // ─── Animated Ambient Bottom Glow ───
            AnimatedBuilder(
              animation: _cardShimmerController,
              builder: (context, child) {
                final pulse = 0.30 +
                    0.10 *
                        math.cos(_cardShimmerController.value * math.pi * 2);
                return Positioned(
                  bottom: -80,
                  left: -80,
                  child: AppDecorations.ambientGlowOrb(
                    color: secondaryAccent,
                    size: 360,
                    opacity: pulse,
                  ),
                );
              },
            ),

            // ─── Main Content ───
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),

                    // ─── Card Entrance Animation ───
                    child: AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _cardOpacity.value,
                          child: Transform.scale(
                            scale: _cardScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildAnimatedCard(
                        palette: palette,
                        isDark: isDark,
                        primaryAccent: primaryAccent,
                        secondaryAccent: secondaryAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main glass card with continuous shimmer border effect
  Widget _buildAnimatedCard({
    required AppPalette palette,
    required bool isDark,
    required Color primaryAccent,
    required Color secondaryAccent,
  }) {
    return AnimatedBuilder(
      animation: _cardShimmerController,
      builder: (context, child) {
        final shimmerAngle = _cardShimmerController.value * 2 * math.pi;
        return Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            // Glass gradient surface
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.04),
                    ]
                  : [
                      Colors.white.withOpacity(0.88),
                      Colors.white.withOpacity(0.72),
                    ],
            ),
            // Animated rotating gradient border
            border: Border.all(
              color: Color.lerp(
                primaryAccent.withOpacity(0.4),
                secondaryAccent.withOpacity(0.4),
                (math.sin(shimmerAngle) + 1) / 2,
              )!,
              width: 1.4,
            ),
            boxShadow: [
              // Depth shadow
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              // Animated chromatic glow
              BoxShadow(
                color: Color.lerp(
                  primaryAccent.withOpacity(isDark ? 0.18 : 0.08),
                  secondaryAccent.withOpacity(isDark ? 0.18 : 0.08),
                  (math.sin(shimmerAngle) + 1) / 2,
                )!,
                blurRadius: 26 + 6 * math.sin(shimmerAngle),
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Animated Logo ───
            _buildAnimatedLogo(primaryAccent, secondaryAccent),

            const SizedBox(height: 20),

            // ─── Animated Heading ───
            _buildAnimatedHeading(primaryAccent, secondaryAccent, isDark),

            const SizedBox(height: 6),

            // ─── Animated Subtitle ───
            _buildAnimatedSubtitle(isDark),

            const SizedBox(height: 32),

            // ─── Animated Form Fields (With Instant Database Auto-Fill) ───
            _buildAnimatedFormFields(primaryAccent, secondaryAccent, isDark, palette),

            const SizedBox(height: 12),

            // ─── Remember Me & Forgot Password (OVERFLOW FIXED) ───
            _buildRememberForgotRow(primaryAccent, isDark),

            const SizedBox(height: 24),

            // ─── Animated Sign In Button ───
            _buildAnimatedSignInButton(palette, primaryAccent, secondaryAccent),

            const SizedBox(height: 12),

            // ─── Animated Quick Demo Explorer ───
            _buildAnimatedDemoButton(
                palette, primaryAccent, secondaryAccent, isDark),

            const SizedBox(height: 24),

            // ─── Animated Footer ───
            _buildAnimatedFooter(primaryAccent, isDark),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  LOGO — pulsing glow + scale breathing + rotating ring
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnimatedLogo(Color primary, Color secondary) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoPulseController, _entranceController]),
      builder: (context, child) {
        final breathe = _logoPulseController.value;
        final scale = 1.0 + 0.06 * math.sin(breathe * math.pi);
        final glowOpacity = 0.4 + 0.25 * math.sin(breathe * math.pi);
        final ringRotation = breathe * math.pi * 0.5;

        return FadeTransition(
          opacity: _logoOpacity,
          child: ScaleTransition(
            scale: _logoScale,
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      Transform.rotate(
                        angle: ringRotation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primary.withOpacity(0.25 + 0.15 * breathe),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // Inner glowing circle
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primary, secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(glowOpacity),
                              blurRadius: 24 + 8 * breathe,
                              spreadRadius: 2 * breathe,
                            ),
                            BoxShadow(
                              color: secondary.withOpacity(glowOpacity * 0.6),
                              blurRadius: 16 + 6 * breathe,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          size: 34,
                          color: Colors.black,
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
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  HEADING — shimmer gradient text sweep
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnimatedHeading(Color primary, Color secondary, bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerController, _entranceController]),
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        final baseColor = isDark ? Colors.white : const Color(0xFF0F172A);

        return SlideTransition(
          position: _headingSlide,
          child: FadeTransition(
            opacity: _headingOpacity,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-1.0 + 3.0 * shimmerValue, 0),
                  end: Alignment(-0.5 + 3.0 * shimmerValue, 0),
                  colors: [
                    baseColor,
                    primary.withOpacity(0.9),
                    secondary.withOpacity(0.8),
                    baseColor,
                  ],
                  stops: const [0.0, 0.4, 0.6, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SUBTITLE — fade-in slide-up with subtle glow
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnimatedSubtitle(bool isDark) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return SlideTransition(
          position: _subtitleSlide,
          child: FadeTransition(
            opacity: _subtitleOpacity,
            child: child,
          ),
        );
      },
      child: Text(
        'Sign in to explore 200+ live songs and 3D soundscapes',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white60 : Colors.black54,
          height: 1.4,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  FORM FIELDS — immediate database auto-detection and auto-fill
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnimatedFormFields(
      Color primaryAccent, Color secondaryAccent, bool isDark, AppPalette palette) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return SlideTransition(
          position: _formSlide,
          child: FadeTransition(
            opacity: _formOpacity,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                color: primaryAccent,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: primaryAccent,
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.8),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Email is required';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          // Quick Saved Account Chips (if user has accounts saved in database)
          if (_savedAccounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _savedAccounts.keys.map((savedEmail) {
                  final isCurrent =
                      _emailController.text.trim().toLowerCase() == savedEmail.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _emailController.text = savedEmail;
                          _passwordController.text = _savedAccounts[savedEmail] ?? '';
                          _isAutofilled = true;
                          _rememberMe = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isCurrent
                              ? primaryAccent.withOpacity(0.15)
                              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                          border: Border.all(
                            color: isCurrent ? primaryAccent.withOpacity(0.6) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_circle_outlined,
                                size: 14,
                                color: isCurrent ? primaryAccent : (isDark ? Colors.white54 : Colors.black54)),
                            const SizedBox(width: 5),
                            Text(
                              savedEmail,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                color: isCurrent ? primaryAccent : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: primaryAccent,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: _isAutofilled
                      ? primaryAccent.withOpacity(0.5)
                      : (isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.12)),
                  width: _isAutofilled ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: primaryAccent,
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.8),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Password is required';
              }
              if (val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          // ─── Instant Database Auto-Fill Notification Badge ───
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                _isAutofilled ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: primaryAccent.withOpacity(0.12),
                        border: Border.all(
                          color: primaryAccent.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 13,
                            color: primaryAccent,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Password detected & auto-filled',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  REMEMBER ME & FORGOT PASSWORD — OVERFLOW FIXED
  //  Live synchronization with persistent credentials database
  // ══════════════════════════════════════════════════════════════
  Widget _buildRememberForgotRow(Color primaryAccent, bool isDark) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _formOpacity,
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Remember Me (flex to prevent overflow + sync with database) ──
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: primaryAccent,
                    checkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (val) async {
                      final newVal = val ?? true;
                      setState(() {
                        _rememberMe = newVal;
                      });

                      final authRepo = context.read<AuthRepository>();
                      await authRepo.setRememberMeEnabled(newVal);

                      final email = _emailController.text.trim();
                      final password = _passwordController.text;

                      if (newVal) {
                        if (email.isNotEmpty && password.isNotEmpty) {
                          await authRepo.saveCredentials(email, password);
                          if (mounted) {
                            setState(() {
                              _isAutofilled = true;
                            });
                          }
                        }
                      } else {
                        if (email.isNotEmpty) {
                          await authRepo.removeCredentials(email);
                          if (mounted) {
                            setState(() {
                              _isAutofilled = false;
                            });
                          }
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Remember me',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // ── Forgot Password ──
          Flexible(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _showForgotPasswordDialog,
              child: Text(
                'Forgot password?',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SIGN IN BUTTON — glowing pulse animation + 3D depth
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnimatedSignInButton(
      AppPalette palette, Color primary, Color secondary) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_buttonGlowController, _entranceController]),
      builder: (context, child) {
        final glowPulse = _buttonGlowController.value;
        final glowIntensity = 0.45 + 0.25 * math.sin(glowPulse * math.pi);
        final spreadPulse = 1.0 * math.sin(glowPulse * math.pi);

        return SlideTransition(
          position: _buttonSlide,
          child: FadeTransition(
            opacity: _buttonOpacity,
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return GestureDetector(
                  onTap: isLoading ? null : _submit,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [primary, secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              primary.withOpacity(isLoading ? 0.3 : glowIntensity),
                          blurRadius: isLoading ? 14 : 20 + 8 * glowPulse,
                          spreadRadius: isLoading ? -2 : spreadPulse,
                          offset: Offset(0, isLoading ? 4 : 6),
                        ),
                        BoxShadow(
                          color: secondary.withOpacity(0.25),
                          blurRadius: 16,
                          spreadRadius: -4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.black,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  QUICK DEMO EXPLORER — glowy redesign with animated border
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnimatedDemoButton(
      AppPalette palette, Color primary, Color secondary, bool isDark) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_cardShimmerController, _entranceController]),
      builder: (context, child) {
        final shimmer = _cardShimmerController.value;
        final borderColor = Color.lerp(
          primary.withOpacity(0.35),
          secondary.withOpacity(0.35),
          (math.sin(shimmer * math.pi * 2) + 1) / 2,
        )!;
        final iconGlow = 0.5 + 0.3 * math.sin(shimmer * math.pi * 2);

        return SlideTransition(
          position: _buttonSlide,
          child: FadeTransition(
            opacity: _buttonOpacity,
            child: GestureDetector(
              onTap: () {
                context.read<AuthCubit>().signIn(
                      email: 'alex@lumawave.io',
                      password: 'SecurePass123!@#',
                      rememberMe: true,
                    );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.02),
                  border: Border.all(color: borderColor, width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(isDark ? 0.08 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated glowing bolt icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            primary.withOpacity(0.2),
                            secondary.withOpacity(0.15),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(iconGlow * 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.flash_on_rounded,
                        size: 16,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Quick Demo Explorer',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  FOOTER — fade-in with themed accent
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnimatedFooter(Color primaryAccent, bool isDark) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _footerOpacity,
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
            child: Text(
              'Create Account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
