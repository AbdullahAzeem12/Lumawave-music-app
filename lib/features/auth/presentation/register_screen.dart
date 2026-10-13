import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/password_validator.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_state.dart';
import '../../home/presentation/main_navigation_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrengthResult _strengthResult = const PasswordStrengthResult(
    score: 0.0,
    strength: PasswordStrength.weak,
    label: 'Empty',
    color: Colors.grey,
    feedback: [],
  );

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _strengthResult = PasswordValidator.evaluate(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<AuthCubit>().register(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);
    final secondaryAccent = AppColors.secondaryColor(palette);

    // [WIDGET PURPOSE]: BlocListener
    // [LAYOUT PROBLEM SOLVED]: Handles state transition logic (navigation on success, error messages on failure).
    // [BEHAVIOR & CONSTRAINTS]: Non-rendering widget that executes side effects.
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigationShell(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            (route) => false,
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      // [WIDGET PURPOSE]: Scaffold
      // [LAYOUT PROBLEM SOLVED]: Provides the structural layout foundation with top bar and body bounds.
      // [BEHAVIOR & CONSTRAINTS]: Imposes viewport boundaries and background styling.
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor(palette, isDark),
        // [WIDGET PURPOSE]: Stack
        // [LAYOUT PROBLEM SOLVED]: Layers ambient radial neon glow backdrops behind the registration card.
        // [BEHAVIOR & CONSTRAINTS]: Permits overlapping visual effects without altering layout constraints.
        body: Stack(
          children: [
            // Ambient Glow (Top Right)
            Positioned(
              top: -80,
              right: -80,
              child: AppDecorations.ambientGlowOrb(
                color: primaryAccent,
                size: 340,
                opacity: 0.40,
              ),
            ),

            // Ambient Glow (Bottom Left)
            Positioned(
              bottom: -80,
              left: -80,
              child: AppDecorations.ambientGlowOrb(
                color: secondaryAccent,
                size: 360,
                opacity: 0.35,
              ),
            ),

            // [WIDGET PURPOSE]: SafeArea
            // [LAYOUT PROBLEM SOLVED]: Ensures contents stay within hardware screen bounds and avoid notches.
            // [BEHAVIOR & CONSTRAINTS]: Offsets children according to window padding.
            SafeArea(
              // [WIDGET PURPOSE]: Center
              // [LAYOUT PROBLEM SOLVED]: Centers the card horizontally and vertically on all displays.
              // [BEHAVIOR & CONSTRAINTS]: Expands to fit viewport and places child at center.
              child: Center(
                // [WIDGET PURPOSE]: SingleChildScrollView
                // [LAYOUT PROBLEM SOLVED]: Enables smooth scrolling when inputs and keyboard take up screen space.
                // [BEHAVIOR & CONSTRAINTS]: Expands bounds into a scrollable viewport.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  // [WIDGET PURPOSE]: ConstrainedBox
                  // [LAYOUT PROBLEM SOLVED]: Clamps maximum card width on tablets and desktop monitors.
                  // [BEHAVIOR & CONSTRAINTS]: Max width set to 500 pixels.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    // [WIDGET PURPOSE]: Container
                    // [LAYOUT PROBLEM SOLVED]: Creates the 3D Glassmorphic card surface with specular borders.
                    // [BEHAVIOR & CONSTRAINTS]: Applies padding, border radius, and dual-layer shadows.
                    child: Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: AppDecorations.glassCard3D(
                        context: context,
                        palette: palette,
                        isDark: isDark,
                        borderRadius: 32.0,
                      ),
                      // [WIDGET PURPOSE]: Form
                      // [LAYOUT PROBLEM SOLVED]: Unifies input validation state for the complete registration form.
                      // [BEHAVIOR & CONSTRAINTS]: Coordinates form fields via GlobalKey.
                      child: Form(
                        key: _formKey,
                        // [WIDGET PURPOSE]: Column
                        // [LAYOUT PROBLEM SOLVED]: Stacks input fields, strength meter, and actions vertically.
                        // [BEHAVIOR & CONSTRAINTS]: Shrink-wraps vertically using MainAxisSize.min.
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back Button and Title Row
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Padding(
                              padding: const EdgeInsets.only(left: 48),
                              child: Text(
                                'Join LumaWave for personalized playlists & 3D audio',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Full Name Field
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                prefixIcon: Icon(Icons.person_outline_rounded, color: primaryAccent),
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
                                  borderSide: BorderSide(color: primaryAccent, width: 1.8),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                prefixIcon: Icon(Icons.alternate_email_rounded, color: primaryAccent),
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
                                  borderSide: BorderSide(color: primaryAccent, width: 1.8),
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

                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryAccent),
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
                                    color: isDark
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: primaryAccent, width: 1.8),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Password is required';
                                }
                                if (val.length < 8) {
                                  return 'Must be at least 8 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            // Real-time Password Strength Meter Bar
                            if (_passwordController.text.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Strength: ${_strengthResult.label}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _strengthResult.color,
                                    ),
                                  ),
                                  Text(
                                    '${(_strengthResult.score * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _strengthResult.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _strengthResult.score,
                                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                  valueColor: AlwaysStoppedAnimation<Color>(_strengthResult.color),
                                  minHeight: 5,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else
                              const SizedBox(height: 6),

                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Re-enter Password',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                prefixIcon: Icon(Icons.lock_reset_rounded, color: primaryAccent),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: isDark ? Colors.white60 : Colors.black45,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
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
                                    color: isDark
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: primaryAccent, width: 1.8),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please re-enter your password';
                                }
                                if (val != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 28),

                            // Submit Button
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;

                                return GestureDetector(
                                  onTap: isLoading ? null : _submit,
                                  child: Container(
                                    height: 54,
                                    decoration: AppDecorations.primary3DButton(
                                      palette: palette,
                                      isPressed: isLoading,
                                      borderRadius: 20,
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
                                            'Create Account',
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

                            const SizedBox(height: 20),

                            // Return to Sign In Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}
