import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../../auth/presentation/sign_in_screen.dart';
import '../../../core/widgets/smooth_scroller.dart';
import '../../../core/widgets/interactive_bounce_button.dart';
import 'widgets/avatar_crop_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Curated studio avatars available for instant selection without requiring device permissions
  static const List<Map<String, String>> _curatedStudioAvatars = [
    {
      'id': 'cyber_neon',
      'name': 'Cyber Beats',
      'label': 'Synth & Electric',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    },
    {
      'id': 'lofi_chill',
      'name': 'Lo-Fi Chill',
      'label': 'Acoustic & Calm',
      'url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80',
    },
    {
      'id': 'studio_pro',
      'name': 'Studio Master',
      'label': 'Producer & Mix',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
    },
    {
      'id': 'vinyl_groove',
      'name': 'Vinyl Groove',
      'label': 'Retro Soul',
      'url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&auto=format&fit=crop&q=80',
    },
    {
      'id': 'cosmic_pulse',
      'name': 'Cosmic Pulse',
      'label': 'Ambient Sound',
      'url': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&auto=format&fit=crop&q=80',
    },
    {
      'id': 'sound_wave',
      'name': 'Sound Wave',
      'label': 'Bass & Rhythm',
      'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
    },
  ];

  /// Displays the interactive bottom sheet for uploading or updating avatar
  void _showAvatarOptionsSheet(
    BuildContext context,
    UserModel? user,
    AppPalette palette,
    bool isDark,
  ) {
    final primaryAccent = AppColors.primaryColor(palette);
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131520) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
                blurRadius: 36,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Grab Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title & Subtitle Header
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
                        Icons.camera_alt_rounded,
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
                            hasPhoto ? 'Update Profile Picture' : 'Add Profile Picture',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasPhoto
                                ? 'Choose a curated persona or select a custom image'
                                : 'Personalize your Pulse listening profile',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // SECTION 1: Curated Studio Personas
                Text(
                  'CURATED STUDIO PERSONAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 98,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _curatedStudioAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (ctx, index) {
                      final item = _curatedStudioAvatars[index];
                      final isSelected = user?.photoUrl == item['url'];

                      return InteractiveBounceButton(
                        pressScale: 0.90,
                        onTap: () async {
                          Navigator.of(bottomSheetContext).pop();
                          try {
                            await context.read<AuthCubit>().updateProfilePictureUrl(item['url']!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.mintAccent, size: 20),
                                      const SizedBox(width: 10),
                                      Text('${item['name']} avatar applied successfully!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF0F172A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update avatar: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? primaryAccent : (isDark ? Colors.white24 : Colors.black12),
                                  width: isSelected ? 2.5 : 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: primaryAccent.withOpacity(0.45),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: item['url']!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: primaryAccent.withOpacity(0.2),
                                    child: Icon(Icons.person_rounded, color: primaryAccent, size: 28),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['name']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? primaryAccent
                                    : (isDark ? Colors.white.withOpacity(0.8) : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.white10 : Colors.black12,
                  height: 1,
                ),
                const SizedBox(height: 16),

                // SECTION 2: Custom Gallery / Camera Pickers with Rapid Bounce
                InteractiveBounceButton(
                  pressScale: 0.94,
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndCropImage(context, ImageSource.gallery, palette, isDark);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: primaryAccent.withOpacity(0.18),
                          ),
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: primaryAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose from Gallery',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Select from device storage & crop to fit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),

                InteractiveBounceButton(
                  pressScale: 0.94,
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndCropImage(context, ImageSource.camera, palette, isDark);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: EdgeInsets.only(bottom: hasPhoto ? 10 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.secondaryColor(palette).withOpacity(0.18),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            color: AppColors.secondaryColor(palette),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Take a Photo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Capture with phone camera & adjust frame',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),

                // Option 3: Remove Current Profile Picture (if exists)
                if (hasPhoto)
                  InteractiveBounceButton(
                    pressScale: 0.94,
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      _confirmRemovePhoto(context, palette, isDark);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: AppColors.error.withOpacity(0.1),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.error.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remove Picture',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.error,
                                  ),
                                ),
                                Text(
                                  'Revert back to your listening badge initials',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Picks image from Gallery/Camera, opens crop & edit modal, and persists to Supabase
  Future<void> _pickAndCropImage(
    BuildContext context,
    ImageSource source,
    AppPalette palette,
    bool isDark,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile == null || !context.mounted) return;

      // Launch interactive crop & edit modal
      final Uint8List? croppedBytes = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AvatarCropModal(
          imageFile: File(pickedFile.path),
          palette: palette,
          isDark: isDark,
        ),
      );

      if (croppedBytes == null || !context.mounted) return;

      // Show uploading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 14),
              Text(
                'Saving profile picture to Supabase cloud...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

      // Save to Supabase Storage and user metadata
      await context.read<AuthCubit>().updateProfilePicture(
        croppedBytes,
        extension: 'png',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.mintAccent, size: 22),
                SizedBox(width: 12),
                Text(
                  'Profile picture updated successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } on PlatformException catch (pEx) {
      if (context.mounted) {
        if (pEx.code == 'channel-error' || pEx.message?.contains('ImagePickerApi') == true) {
          _showPluginReloadDialog(context, palette, isDark);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image picker error: ${pEx.message ?? pEx.code}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $err'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  /// Displays a friendly glass dialog explaining the Android plugin channel binding
  void _showPluginReloadDialog(
    BuildContext context,
    AppPalette palette,
    bool isDark,
  ) {
    final primaryAccent = AppColors.primaryColor(palette);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient(palette),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Restart App for Camera & Gallery',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'To connect your physical phone\'s camera & gallery, please run "flutter run" in your terminal once.\n\nIn the meantime, you can instantly choose any Curated Studio Persona!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InteractiveBounceButton(
                      pressScale: 0.94,
                      onTap: () => Navigator.of(ctx).pop(),
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
                            'Got It',
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
                        Navigator.of(ctx).pop();
                        final authState = context.read<AuthCubit>().state;
                        final user = (authState is Authenticated) ? authState.user : null;
                        _showAvatarOptionsSheet(context, user, palette, isDark);
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
                            'Pick Persona',
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
      ),
    );
  }

  /// Confirms and executes profile picture removal with a 3D glass dialog and rapid bounce buttons
  Future<void> _confirmRemovePhoto(
    BuildContext context,
    AppPalette palette,
    bool isDark,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isDark ? const Color(0xFF131520) : Colors.white,
            border: Border.all(
              color: AppColors.error.withOpacity(0.35),
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
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(0.18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Remove Profile Picture?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your custom profile photo will be cleared and replaced with your vibrant listening badge initials.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InteractiveBounceButton(
                      pressScale: 0.94,
                      onTap: () => Navigator.of(ctx).pop(false),
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
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.error,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Remove Photo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthCubit>().removeProfilePicture();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Profile picture removed'),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  /// Builds a bulletproof avatar image with multi-tier error suppression and fallbacks
  Widget _buildAvatarImage(String photoUrl, UserModel? user, AppPalette palette) {
    if (photoUrl.isEmpty) {
      return _buildInitialsFallback(user, palette);
    }

    // Handle base64 encoded data URI or raw base64 data
    if (photoUrl.startsWith('data:image') || (!photoUrl.startsWith('http://') && !photoUrl.startsWith('https://') && photoUrl.length > 80)) {
      try {
        final base64String = photoUrl.contains(',')
            ? photoUrl.split(',').last.trim()
            : photoUrl.trim();
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialsFallback(user, palette),
        );
      } catch (_) {
        return _buildInitialsFallback(user, palette);
      }
    }

    // Network image (Supabase Cloud Storage or curated studio avatar)
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor(palette)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitialsFallback(user, palette),
      );
    }

    return _buildInitialsFallback(user, palette);
  }

  Widget _buildInitialsFallback(UserModel? user, AppPalette palette) {
    return Center(
      child: Text(
        (user?.displayName.isNotEmpty == true)
            ? user!.displayName[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final palette = themeState.palette;
    final isDark = themeState.isDark;
    final primaryAccent = AppColors.primaryColor(palette);

    final authState = context.watch<AuthCubit>().state;
    final user = (authState is Authenticated) ? authState.user : null;
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;

    // [WIDGET PURPOSE]: Scaffold
    // [LAYOUT PROBLEM SOLVED]: Frame structure for the Profile and Settings customization screen.
    // [BEHAVIOR & CONSTRAINTS]: Imposes bounds and theme styling.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // [WIDGET PURPOSE]: SafeArea
      // [LAYOUT PROBLEM SOLVED]: Ensures settings items remain clear of device status bar and gestures.
      // [BEHAVIOR & CONSTRAINTS]: Resolves hardware insets.
      body: SafeArea(
        child: PulseSmoothScroller(
          controller: _scrollController,
          palette: palette,
          isDark: isDark,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Profile & Themes',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 24),

                // User Profile 3D Card with Interactive Avatar
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: AppDecorations.glassCard3D(
                    context: context,
                    palette: palette,
                    isDark: isDark,
                    borderRadius: 24,
                  ),
                  child: Row(
                    children: [
                      // Avatar Icon with micro-spring tap bounce & camera badge
                      InteractiveBounceButton(
                        pressScale: 0.92,
                        onTap: () => _showAvatarOptionsSheet(context, user, palette, isDark),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient(palette),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: hasPhoto
                                    ? _buildAvatarImage(user.photoUrl!, user, palette)
                                    : _buildInitialsFallback(user, palette),
                              ),
                            ),

                            // Camera / Edit overlay badge
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryAccent,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF131520) : Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 11,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Guest User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? 'Not logged in',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: AppColors.mintAccent.withOpacity(0.18),
                                  ),
                                  child: const Text(
                                    'VERIFIED LISTENER',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.mintAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap photo to edit',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // SECTION: Theme Mode (Light / Dark / System)
                Text(
                  'APPEARANCE MODE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        context: context,
                        label: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        isSelected: themeState.themeMode == ThemeMode.dark,
                        palette: palette,
                        isDark: isDark,
                        onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeButton(
                        context: context,
                        label: 'Light',
                        icon: Icons.light_mode_rounded,
                        isSelected: themeState.themeMode == ThemeMode.light,
                        palette: palette,
                        isDark: isDark,
                        onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeButton(
                        context: context,
                        label: 'System',
                        icon: Icons.brightness_auto_rounded,
                        isSelected: themeState.themeMode == ThemeMode.system,
                        palette: palette,
                        isDark: isDark,
                        onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.system),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // SECTION: The 4 Distinct Palettes
                Text(
                  'COLOR PALETTES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPaletteTile(
                  context: context,
                  paletteOption: AppPalette.obsidianAurora,
                  title: 'Obsidian Aurora',
                  subtitle: 'Deep Midnight with Electric Cyan & Violet',
                  gradient: const [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                  isSelected: palette == AppPalette.obsidianAurora,
                ),
                const SizedBox(height: 10),
                _buildPaletteTile(
                  context: context,
                  paletteOption: AppPalette.pearlPrism,
                  title: 'Pearl Prism',
                  subtitle: 'Pristine Alabaster with Iridescent Lilac & Rose',
                  gradient: const [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
                  isSelected: palette == AppPalette.pearlPrism,
                ),
                const SizedBox(height: 10),
                _buildPaletteTile(
                  context: context,
                  paletteOption: AppPalette.emeraldSound,
                  title: 'Emerald Sound',
                  subtitle: 'Abyssal Green with Acoustic Mint & Forest Cyan',
                  gradient: const [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                  isSelected: palette == AppPalette.emeraldSound,
                ),
                const SizedBox(height: 10),
                _buildPaletteTile(
                  context: context,
                  paletteOption: AppPalette.velvetSunset,
                  title: 'Velvet Sunset',
                  subtitle: 'Royal Plum with Sunset Magenta & Solar Amber',
                  gradient: const [Color(0xFFFA709A), Color(0xFFFEE140)],
                  isSelected: palette == AppPalette.velvetSunset,
                ),

                const SizedBox(height: 32),

                // Sign Out Button with Interactive Spring Feedback
                InteractiveBounceButton(
                  pressScale: 0.96,
                  onTap: () async {
                    await context.read<AuthCubit>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.error.withOpacity(0.12),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required AppPalette palette,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryAccent = AppColors.primaryColor(palette);
    return InteractiveBounceButton(
      pressScale: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected
              ? primaryAccent.withOpacity(isDark ? 0.22 : 0.16)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
          border: Border.all(
            color: isSelected ? primaryAccent : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryAccent.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? primaryAccent : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryAccent : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteTile({
    required BuildContext context,
    required AppPalette paletteOption,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required bool isSelected,
  }) {
    final isDark = context.read<ThemeCubit>().state.isDark;
    return InteractiveBounceButton(
      pressScale: 0.97,
      onTap: () => context.read<ThemeCubit>().setPalette(paletteOption),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
          border: Border.all(
            color: isSelected ? gradient.first : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(Icons.check_circle_rounded, color: gradient.first, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
