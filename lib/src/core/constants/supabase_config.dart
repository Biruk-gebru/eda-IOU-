class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Supabase credentials are missing. Provide SUPABASE_URL and '
        'SUPABASE_ANON_KEY via --dart-define or environment injection.',
      );
    }
  }
}
