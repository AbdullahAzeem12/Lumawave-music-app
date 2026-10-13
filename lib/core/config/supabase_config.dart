import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  /// Supabase Project URL from your Supabase Dashboard -> Project Settings -> API
  /// (e.g. 'https://abcdefghijklm.supabase.co')
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hacpudduvbyyfrehrdzy.supabase.co',
  );

  /// Supabase Public Anon Key from your Supabase Dashboard -> Project Settings -> API
  /// (e.g. 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...')
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhhY3B1ZGR1dmJ5eWZyZWhyZHp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjI2NjQsImV4cCI6MjEwNzM5ODY2NH0.cOaznxSDj1d_UrxUx40mqe7yk9s9_y6XWIdDVWFgxKU',
  );

  /// Public live hosted URL for email verification confirmation (bypasses localhost:3000 error)
  static const String emailRedirectTo = 'https://moodmuse-9472d.web.app';

  /// Returns true if valid custom Supabase project credentials are configured
  static bool get isConfigured {
    return url.isNotEmpty &&
        !url.contains('xyzcompany.supabase.co') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('your-anon-key-here');
  }

  /// Safe accessor for the SupabaseClient instance
  static SupabaseClient? get client {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes Supabase for Flutter
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        '[SupabaseConfig] Supabase running in local/hybrid mode. '
        'Add your URL and anonKey in lib/core/config/supabase_config.dart to sync with live Supabase cloud.',
      );
      return;
    }

    try {
      await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode);
      debugPrint('[SupabaseConfig] Supabase client initialized successfully.');
    } catch (e) {
      debugPrint('[SupabaseConfig] Error initializing Supabase: $e');
    }
  }
}
