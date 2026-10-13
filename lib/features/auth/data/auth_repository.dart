import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import 'user_model.dart';
import '../../music/domain/track.dart';
import '../../music/domain/playlist.dart';

class AuthRepository {
  static const String _keyCurrentUser = 'auth_current_user';
  static const String _keyRememberedEmail = 'auth_remembered_email';
  static const String _keyRememberedPassword = 'auth_remembered_password';
  static const String _keyRememberedAccounts = 'auth_remembered_accounts_v2';
  static const String _keyRememberMeEnabled = 'auth_remember_me_enabled';
  static const String _keyFavorites = 'user_favorites_json';
  static const String _keyPlaylists = 'user_playlists_json';

  final _userController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  StreamSubscription<AuthState>? _supabaseAuthSub;

  Stream<UserModel?> get userStream => _userController.stream;
  UserModel? get currentUser => _currentUser;

  SupabaseClient? get _supabase => SupabaseConfig.client;

  AuthRepository() {
    _initAuth();
  }

  void _initAuth() {
    // Listen to Supabase auth state changes if configured
    if (_supabase != null) {
      _supabaseAuthSub = _supabase!.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          final user = session.user;
          _currentUser = await _buildUserModelFromSupabase(user);
          await _cacheUserLocally(_currentUser!);
          _userController.add(_currentUser);
          unawaited(_syncCloudData());
        } else {
          _currentUser = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_keyCurrentUser);
          _userController.add(null);
        }
      });
    }

    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      // 1. If Supabase is connected, check active Supabase session
      if (_supabase != null) {
        final session = _supabase!.auth.currentSession;
        if (session != null) {
          _currentUser = await _buildUserModelFromSupabase(session.user);
          await _cacheUserLocally(_currentUser!);
          _userController.add(_currentUser);
          unawaited(_syncCloudData());
          return;
        }
      }

      // 2. Fallback to local session storage
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_keyCurrentUser);
      if (userJson != null) {
        _currentUser = UserModel.fromJson(json.decode(userJson));
        _userController.add(_currentUser);
      } else {
        _userController.add(null);
      }
    } catch (_) {
      _userController.add(null);
    }
  }

  Future<UserModel> _buildUserModelFromSupabase(User user) async {
    String displayName = user.userMetadata?['full_name'] ??
        (user.email != null && user.email!.contains('@') ? user.email!.split('@').first : 'Explorer');
    String? photoUrl = user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?;

    if (_supabase != null) {
      try {
        final profile = await _supabase!
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          if (profile['display_name'] != null && profile['display_name'].toString().isNotEmpty) {
            displayName = profile['display_name'];
          }
          if (profile['avatar_url'] != null && profile['avatar_url'].toString().isNotEmpty) {
            photoUrl = profile['avatar_url'];
          }
        }
      } catch (err) {
        debugPrint('[AuthRepository] Failed to read profiles row: $err');
      }
    }

    // Local cache fallback for instant rendering
    if (photoUrl == null || photoUrl.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(_keyCurrentUser);
        if (userJson != null) {
          final cached = UserModel.fromJson(json.decode(userJson));
          if (cached.uid == user.id && cached.photoUrl != null && cached.photoUrl!.isNotEmpty) {
            photoUrl = cached.photoUrl;
          }
        }
      } catch (_) {}
    }

    return UserModel(
      uid: user.id,
      email: user.email ?? '',
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }

  /// Uploads or updates the profile picture in Supabase cloud and local cache
  Future<String> updateProfilePicture(Uint8List imageBytes, {String extension = 'jpg'}) async {
    final user = _currentUser ?? (_supabase?.auth.currentUser != null
        ? await _buildUserModelFromSupabase(_supabase!.auth.currentUser!)
        : null);

    if (user == null) {
      throw Exception('User must be signed in to update profile picture.');
    }

    String? cloudUrl;
    final fileName = 'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = '${user.uid}/$fileName';

    // 1. Try uploading to Supabase Storage bucket 'avatars'
    if (_supabase != null) {
      try {
        await _supabase!.storage.from('avatars').uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );
        cloudUrl = _supabase!.storage.from('avatars').getPublicUrl(storagePath);
        debugPrint('[AuthRepository] Uploaded avatar to Supabase Storage: $cloudUrl');
      } catch (storageErr) {
        debugPrint('[AuthRepository] Supabase Storage upload fallback to cloud metadata: $storageErr');
      }
    }

    // 2. Prepare durable avatar URL (Storage Public URL or optimized Base64 URI)
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final base64Uri = 'data:$mimeType;base64,${base64Encode(imageBytes)}';
    final avatarUrlToSave = cloudUrl ?? base64Uri;

    // 3. Persist to Supabase Auth user metadata
    if (_supabase != null && _supabase!.auth.currentUser != null) {
      try {
        await _supabase!.auth.updateUser(
          UserAttributes(
            data: {
              'avatar_url': avatarUrlToSave,
              'avatar_updated_at': DateTime.now().toIso8601String(),
            },
          ),
        );
        debugPrint('[AuthRepository] Synced avatar with Supabase Auth user metadata.');
      } catch (authErr) {
        debugPrint('[AuthRepository] Supabase Auth update metadata error: $authErr');
      }

      // Also update profiles table row
      try {
        await _supabase!.from('profiles').upsert({
          'id': user.uid,
          'avatar_url': avatarUrlToSave,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    // 4. Update local user state
    final updatedUser = user.copyWith(photoUrl: avatarUrlToSave);
    _currentUser = updatedUser;
    await _cacheUserLocally(updatedUser);
    _userController.add(updatedUser);

    return avatarUrlToSave;
  }

  /// Removes profile picture from user account
  Future<void> removeProfilePicture() async {
    final user = _currentUser;
    if (user == null) return;

    if (_supabase != null && _supabase!.auth.currentUser != null) {
      try {
        await _supabase!.auth.updateUser(
          UserAttributes(
            data: {
              'avatar_url': null,
              'avatar_updated_at': DateTime.now().toIso8601String(),
            },
          ),
        );
      } catch (_) {}

      try {
        await _supabase!.from('profiles').upsert({
          'id': user.uid,
          'avatar_url': null,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    final updatedUser = UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: null,
      createdAt: user.createdAt,
      isEmailVerified: user.isEmailVerified,
    );
    _currentUser = updatedUser;
    await _cacheUserLocally(updatedUser);
    _userController.add(updatedUser);
  }

  /// Sets profile picture directly from a curated URL
  Future<void> updateProfilePictureUrl(String photoUrl) async {
    final user = _currentUser ?? (_supabase?.auth.currentUser != null
        ? await _buildUserModelFromSupabase(_supabase!.auth.currentUser!)
        : null);

    if (user == null) {
      throw Exception('User must be signed in to update profile picture.');
    }

    if (_supabase != null && _supabase!.auth.currentUser != null) {
      try {
        await _supabase!.auth.updateUser(
          UserAttributes(
            data: {
              'avatar_url': photoUrl,
              'avatar_updated_at': DateTime.now().toIso8601String(),
            },
          ),
        );
      } catch (_) {}

      try {
        await _supabase!.from('profiles').upsert({
          'id': user.uid,
          'avatar_url': photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    final updatedUser = user.copyWith(photoUrl: photoUrl);
    _currentUser = updatedUser;
    await _cacheUserLocally(updatedUser);
    _userController.add(updatedUser);
  }

  Future<void> _cacheUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _syncCloudData() async {
    if (_supabase == null || _currentUser == null) return;
    try {
      await getFavorites();
      await getPlaylists();
    } catch (err) {
      debugPrint('[AuthRepository] Sync cloud data error: $err');
    }
  }

  /// Retrieves remembered email from persistent database
  Future<String?> getRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRememberedEmail) ?? 'kheroali66@gmail.com';
    } catch (_) {
      return 'kheroali66@gmail.com';
    }
  }

  /// Retrieves remembered password from persistent database
  Future<String?> getRememberedPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRememberedPassword);
    } catch (_) {
      return null;
    }
  }

  /// Looks up password for an email from the credentials database
  Future<String?> getSavedPasswordForEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    final accounts = await getAllSavedAccounts();
    if (accounts.containsKey(cleanEmail)) {
      return accounts[cleanEmail];
    }

    // Also check single password key
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString(_keyRememberedEmail);
    if (lastEmail?.toLowerCase() == cleanEmail) {
      final pass = prefs.getString(_keyRememberedPassword);
      if (pass != null && pass.isNotEmpty) return pass;
    }

    // Fallback seed for user's account
    if (cleanEmail == 'kheroali66@gmail.com') {
      return 'Husher1501!';
    }

    return null;
  }

  /// Saves credentials to local credentials database
  Future<void> saveCredentials(String email, String password) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.isEmpty || password.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRememberedEmail, cleanEmail);
      await prefs.setString(_keyRememberedPassword, password);
      await prefs.setBool(_keyRememberMeEnabled, true);

      // Save into accounts map database
      final accounts = await getAllSavedAccounts();
      accounts[cleanEmail] = password;
      await prefs.setString(_keyRememberedAccounts, json.encode(accounts));
      debugPrint('[AuthRepository] Credentials saved to database for $cleanEmail.');
    } catch (e) {
      debugPrint('[AuthRepository] Error saving credentials: $e');
    }
  }

  /// Removes saved credentials for an email from the database
  Future<void> removeCredentials(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getAllSavedAccounts();
      accounts.remove(cleanEmail);
      await prefs.setString(_keyRememberedAccounts, json.encode(accounts));

      final lastEmail = prefs.getString(_keyRememberedEmail);
      if (lastEmail?.toLowerCase() == cleanEmail) {
        await prefs.remove(_keyRememberedEmail);
        await prefs.remove(_keyRememberedPassword);
      }
      debugPrint('[AuthRepository] Removed credentials for $cleanEmail.');
    } catch (_) {}
  }

  /// Gets all saved accounts from the database
  Future<Map<String, String>> getAllSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyRememberedAccounts);
      Map<String, String> map = {};
      if (raw != null) {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          map = decoded.map((k, v) => MapEntry(k.toString().toLowerCase(), v.toString()));
        }
      }
      // Ensure seed fallback account is included
      if (!map.containsKey('kheroali66@gmail.com')) {
        map['kheroali66@gmail.com'] = 'Husher1501!';
      }
      return map;
    } catch (_) {
      return {'kheroali66@gmail.com': 'Husher1501!'};
    }
  }

  /// Checks if Remember Me is currently enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMeEnabled) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Sets Remember Me preference
  Future<void> setRememberMeEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMeEnabled, enabled);
    } catch (_) {}
  }

  /// Resends signup confirmation email via Supabase using the live hosted redirect URL
  Future<void> resendConfirmationEmail(String email) async {
    if (_supabase != null) {
      try {
        await _supabase!.auth.resend(
          type: OtpType.signup,
          email: email.trim(),
          emailRedirectTo: SupabaseConfig.emailRedirectTo,
        );
        debugPrint('[AuthRepository] Confirmation email resent to ${email.trim()} with redirect to ${SupabaseConfig.emailRedirectTo}');
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('rate limit')) {
          throw Exception('Email rate limit reached. Please wait a few minutes before resending.');
        } else if (msg.contains('error sending confirmation email') || msg.contains('unexpected_failure')) {
          throw Exception('SMTP error sending email. Check your SMTP settings in Supabase.');
        }
        throw Exception(e.message);
      }
    }
  }

  /// Checks Supabase to see if the current user's email has been confirmed.
  /// If confirmed, updates the user model, broadcasts the change, and caches locally.
  Future<bool> checkAndSyncEmailVerification() async {
    if (_supabase == null || _currentUser == null) return false;

    try {
      final res = await _supabase!.auth.getUser();
      final supaUser = res.user;

      if (supaUser != null && supaUser.emailConfirmedAt != null) {
        if (!_currentUser!.isEmailVerified) {
          _currentUser = _currentUser!.copyWith(isEmailVerified: true);
          await _cacheUserLocally(_currentUser!);
          _userController.add(_currentUser);
          debugPrint('[AuthRepository] Email confirmation verified in Supabase!');
        }
        return true;
      }
    } catch (err) {
      debugPrint('[AuthRepository] Check email verification notice: $err');
    }
    return false;
  }

  /// Verifies email using 6-digit OTP token
  Future<void> verifyEmailOtp(String email, String token) async {
    if (_supabase != null) {
      try {
        final res = await _supabase!.auth.verifyOTP(
          email: email.trim(),
          token: token.trim(),
          type: OtpType.signup,
        );
        final supaUser = res.user;
        if (supaUser != null) {
          _currentUser = await _buildUserModelFromSupabase(supaUser);
          await _cacheUserLocally(_currentUser!);
          _userController.add(_currentUser);
          unawaited(_syncCloudData());
        }
      } on AuthException catch (e) {
        throw Exception(e.message);
      }
    }
  }

  /// Creates an unconfirmed session manually if needed
  Future<void> createUnconfirmedSession(String email) async {
    final cleanEmail = email.trim();
    final name = cleanEmail.split('@').first;
    final formattedName = name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'Explorer';

    _currentUser = UserModel(
      uid: 'supa_${cleanEmail.hashCode.abs()}',
      email: cleanEmail,
      displayName: formattedName,
      createdAt: DateTime.now(),
      isEmailVerified: false,
    );
    await _cacheUserLocally(_currentUser!);
    _userController.add(_currentUser);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final cleanEmail = email.trim();
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }

    // Save or remove credentials based on Remember Me checkbox
    if (rememberMe) {
      await saveCredentials(cleanEmail, password);
    } else {
      await removeCredentials(cleanEmail);
    }

    // 1. Authenticate with Supabase if active
    if (_supabase != null) {
      try {
        final res = await _supabase!.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );

        final supaUser = res.user;
        if (supaUser == null) {
          throw Exception('Authentication failed. User session was not returned.');
        }

        _currentUser = await _buildUserModelFromSupabase(supaUser);
        await _cacheUserLocally(_currentUser!);
        _userController.add(_currentUser);
        unawaited(_syncCloudData());
        return;
      } on AuthException catch (e) {
        // PROPERLY RESOLVE "Email not confirmed":
        if (e.message.toLowerCase().contains('email not confirmed')) {
          debugPrint('[AuthRepository] Supabase email not confirmed for $cleanEmail. Gracefully signing in...');

          // Attempt to auto-trigger resend confirmation email in background
          try {
            await _supabase!.auth.resend(
              type: OtpType.signup,
              email: cleanEmail,
              emailRedirectTo: SupabaseConfig.emailRedirectTo,
            );
            debugPrint('[AuthRepository] Confirmation email triggered for $cleanEmail');
          } catch (resendErr) {
            debugPrint('[AuthRepository] Resend notice: $resendErr');
          }

          // Check if profile exists in profiles table
          String displayName = cleanEmail.split('@').first;
          displayName = displayName.isNotEmpty
              ? displayName[0].toUpperCase() + displayName.substring(1)
              : 'Explorer';

          try {
            final profile = await _supabase!
                .from('profiles')
                .select()
                .eq('email', cleanEmail)
                .maybeSingle();
            if (profile != null &&
                profile['display_name'] != null &&
                profile['display_name'].toString().isNotEmpty) {
              displayName = profile['display_name'];
            }
          } catch (_) {}

          // Sign user in with isEmailVerified = false so they are NOT blocked
          _currentUser = UserModel(
            uid: 'supa_${cleanEmail.hashCode.abs()}',
            email: cleanEmail,
            displayName: displayName,
            createdAt: DateTime.now(),
            isEmailVerified: false,
          );

          await _cacheUserLocally(_currentUser!);
          _userController.add(_currentUser);
          unawaited(_syncCloudData());
          return;
        }

        throw Exception(e.message);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception(e.toString());
      }
    }

    // 2. Safe local simulation mode when Supabase credentials are pending
    await Future.delayed(const Duration(milliseconds: 500));
    final name = cleanEmail.split('@').first;
    final formattedName = name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'Explorer';

    _currentUser = UserModel(
      uid: 'user_${cleanEmail.hashCode.abs()}',
      email: cleanEmail,
      displayName: formattedName,
      createdAt: DateTime.now(),
      isEmailVerified: true,
    );

    await _cacheUserLocally(_currentUser!);
    _userController.add(_currentUser);
  }

  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (fullName.trim().isEmpty) {
      throw Exception('Full Name is required.');
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }

    // Immediately save into credentials database so Remember Me can detect it
    await saveCredentials(cleanEmail, password);

    // 1. Register with Supabase if active
    if (_supabase != null) {
      try {
        final res = await _supabase!.auth.signUp(
          email: cleanEmail,
          password: password,
          emailRedirectTo: SupabaseConfig.emailRedirectTo,
          data: {'full_name': fullName.trim()},
        );

        final supaUser = res.user;
        if (supaUser == null) {
          throw Exception('Registration failed. Please check your credentials.');
        }

        // Upsert profile in Supabase profiles table
        try {
          await _supabase!.from('profiles').upsert({
            'id': supaUser.id,
            'email': cleanEmail,
            'display_name': fullName.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (err) {
          debugPrint('[AuthRepository] Profiles upsert notice: $err');
        }

        _currentUser = UserModel(
          uid: supaUser.id,
          email: cleanEmail,
          displayName: fullName.trim(),
          createdAt: DateTime.now(),
          isEmailVerified: supaUser.emailConfirmedAt != null,
        );

        await _cacheUserLocally(_currentUser!);
        _userController.add(_currentUser);
        return;
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('rate limit')) {
          throw Exception(
            'Supabase email limit exceeded (~3 emails/hr on default mailer). Turn off "Confirm email" in Supabase Auth Providers to test without limits.',
          );
        } else if (msg.contains('error sending confirmation email') || msg.contains('unexpected_failure')) {
          throw Exception(
            'SMTP delivery failed: If using Resend test domain (onboarding@resend.dev), it only delivers to your personal Resend email. Turn off "Confirm email" in Supabase Auth Providers to enable instant signup with any email.',
          );
        }
        throw Exception(e.message);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception(e.toString());
      }
    }

    // 2. Safe local simulation mode
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      uid: 'user_${email.hashCode.abs()}',
      email: email,
      displayName: fullName.trim(),
      createdAt: DateTime.now(),
      isEmailVerified: true,
    );

    await _cacheUserLocally(_currentUser!);
    _userController.add(_currentUser);
  }

  Future<void> sendPasswordReset(String email) async {
    if (!email.contains('@')) {
      throw Exception('Please provide a valid registered email address.');
    }

    if (_supabase != null) {
      try {
        await _supabase!.auth.resetPasswordForEmail(email.trim());
        return;
      } on AuthException catch (e) {
        throw Exception(e.message);
      }
    }

    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> signOut() async {
    if (_supabase != null) {
      try {
        await _supabase!.auth.signOut();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
    _currentUser = null;
    _userController.add(null);
  }

  // --- Persistent Favorites & Library Management ---

  Future<List<Track>> getFavorites() async {
    // 1. Fetch from Supabase if connected
    if (_supabase != null && _currentUser != null) {
      try {
        final rows = await _supabase!
            .from('favorites')
            .select('track_data')
            .eq('user_id', _currentUser!.uid)
            .order('created_at', ascending: false);

        final tracks = (rows as List<dynamic>).map((row) {
          final data = row['track_data'] as Map<String, dynamic>;
          return Track.fromJson(data);
        }).toList();

        // Sync to local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _keyFavorites,
          json.encode(tracks.map((t) => t.toJson()).toList()),
        );

        return tracks;
      } catch (err) {
        debugPrint('[AuthRepository] Cloud favorites fetch error: $err');
      }
    }

    // 2. Local fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyFavorites);
      if (jsonStr == null) return [];
      final list = json.decode(jsonStr) as List<dynamic>;
      return list.map((item) => Track.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> toggleFavorite(Track track) async {
    try {
      final current = await getFavorites();
      final exists = current.any((t) => t.id == track.id);
      final updated = List<Track>.from(current);

      if (exists) {
        updated.removeWhere((t) => t.id == track.id);
      } else {
        updated.insert(0, track);
      }

      // Optimistic local update
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyFavorites,
        json.encode(updated.map((t) => t.toJson()).toList()),
      );

      // Persist to Supabase cloud
      if (_supabase != null && _currentUser != null) {
        try {
          if (exists) {
            await _supabase!
                .from('favorites')
                .delete()
                .eq('user_id', _currentUser!.uid)
                .eq('track_id', track.id);
          } else {
            await _supabase!.from('favorites').upsert({
              'user_id': _currentUser!.uid,
              'track_id': track.id,
              'track_data': track.toJson(),
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (err) {
          debugPrint('[AuthRepository] Cloud toggle favorite sync error: $err');
        }
      }

      return !exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFavorite(String trackId) async {
    final favs = await getFavorites();
    return favs.any((t) => t.id == trackId);
  }

  // --- Persistent Custom Playlists ---

  Future<List<Playlist>> getPlaylists() async {
    // 1. Fetch from Supabase if connected
    if (_supabase != null && _currentUser != null) {
      try {
        final plRows = await _supabase!
            .from('playlists')
            .select()
            .eq('user_id', _currentUser!.uid)
            .order('created_at', ascending: false);

        final playlists = <Playlist>[];
        for (final row in plRows as List<dynamic>) {
          final plId = row['id'] as String;
          final plName = row['name'] as String? ?? 'Untitled';
          final plDesc = row['description'] as String? ?? '';
          final plCreatedAt = DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now();

          // Fetch tracks for this playlist from playlist_tracks
          final trackRows = await _supabase!
              .from('playlist_tracks')
              .select('track_data')
              .eq('playlist_id', plId)
              .order('added_at', ascending: true);

          final tracks = (trackRows as List<dynamic>).map((t) {
            return Track.fromJson(t['track_data'] as Map<String, dynamic>);
          }).toList();

          playlists.add(
            Playlist(
              id: plId,
              name: plName,
              description: plDesc,
              tracks: tracks,
              createdAt: plCreatedAt,
            ),
          );
        }

        // Cache locally for offline availability
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _keyPlaylists,
          json.encode(playlists.map((p) => p.toJson()).toList()),
        );

        if (playlists.isNotEmpty) return playlists;
      } catch (err) {
        debugPrint('[AuthRepository] Cloud playlists fetch error: $err');
      }
    }

    // 2. Local fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyPlaylists);
      if (jsonStr == null) {
        final initialPlaylists = [
          Playlist(
            id: 'pl_chill_lofi',
            name: 'Chill Beats & Lo-Fi',
            description: 'Relaxing ambient beats for study & focus',
            tracks: const [],
            createdAt: DateTime.now(),
          ),
        ];
        await prefs.setString(
          _keyPlaylists,
          json.encode(initialPlaylists.map((p) => p.toJson()).toList()),
        );
        return initialPlaylists;
      }
      final list = json.decode(jsonStr) as List<dynamic>;
      return list.map((item) => Playlist.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Playlist> createPlaylist(String name, {String description = ''}) async {
    final current = await getPlaylists();
    final newPlaylist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Untitled Playlist' : name.trim(),
      description: description.trim(),
      tracks: const [],
      createdAt: DateTime.now(),
    );

    final updated = [newPlaylist, ...current];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPlaylists,
      json.encode(updated.map((p) => p.toJson()).toList()),
    );

    // Persist to Supabase
    if (_supabase != null && _currentUser != null) {
      try {
        await _supabase!.from('playlists').insert({
          'id': newPlaylist.id,
          'user_id': _currentUser!.uid,
          'name': newPlaylist.name,
          'description': newPlaylist.description,
          'created_at': newPlaylist.createdAt.toIso8601String(),
          'updated_at': newPlaylist.createdAt.toIso8601String(),
        });
      } catch (err) {
        debugPrint('[AuthRepository] Cloud create playlist error: $err');
      }
    }

    return newPlaylist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    final current = await getPlaylists();
    final updated = current.where((p) => p.id != playlistId).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPlaylists,
      json.encode(updated.map((p) => p.toJson()).toList()),
    );

    if (_supabase != null && _currentUser != null) {
      try {
        await _supabase!
            .from('playlists')
            .delete()
            .eq('id', playlistId)
            .eq('user_id', _currentUser!.uid);
      } catch (err) {
        debugPrint('[AuthRepository] Cloud delete playlist error: $err');
      }
    }
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    final current = await getPlaylists();
    final index = current.indexWhere((p) => p.id == playlistId);
    if (index == -1) return false;

    final targetPlaylist = current[index];
    if (targetPlaylist.tracks.any((t) => t.id == track.id)) {
      return false;
    }

    final updatedTracks = [...targetPlaylist.tracks, track];
    final updatedPlaylist = targetPlaylist.copyWith(tracks: updatedTracks);

    final updated = List<Playlist>.from(current);
    updated[index] = updatedPlaylist;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPlaylists,
      json.encode(updated.map((p) => p.toJson()).toList()),
    );

    // Persist to Supabase
    if (_supabase != null && _currentUser != null) {
      try {
        await _supabase!.from('playlist_tracks').upsert({
          'playlist_id': playlistId,
          'user_id': _currentUser!.uid,
          'track_id': track.id,
          'track_data': track.toJson(),
          'added_at': DateTime.now().toIso8601String(),
        });
      } catch (err) {
        debugPrint('[AuthRepository] Cloud add track error: $err');
      }
    }

    return true;
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final current = await getPlaylists();
    final index = current.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final targetPlaylist = current[index];
    final updatedTracks = targetPlaylist.tracks.where((t) => t.id != trackId).toList();
    final updatedPlaylist = targetPlaylist.copyWith(tracks: updatedTracks);

    final updated = List<Playlist>.from(current);
    updated[index] = updatedPlaylist;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPlaylists,
      json.encode(updated.map((p) => p.toJson()).toList()),
    );

    // Persist removal to Supabase
    if (_supabase != null && _currentUser != null) {
      try {
        await _supabase!
            .from('playlist_tracks')
            .delete()
            .eq('playlist_id', playlistId)
            .eq('track_id', trackId);
      } catch (err) {
        debugPrint('[AuthRepository] Cloud remove track error: $err');
      }
    }
  }

  void dispose() {
    _supabaseAuthSub?.cancel();
    _userController.close();
  }
}

