import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get oauthRedirectUrl => dotenv.env['SUPABASE_REDIRECT_URL'] ?? 'com.example.eda://login-callback/';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Supabase credentials are missing. Provide SUPABASE_URL and '
        'SUPABASE_ANON_KEY in your .env file.',
      );
    }
  }
}
