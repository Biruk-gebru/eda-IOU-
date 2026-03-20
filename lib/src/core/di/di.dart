import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_config.dart';

Future<void> initializeDependencies() async {
  SupabaseConfig.ensureConfigured();

  await Hive.initFlutter();
  // TODO: Run `dart run build_runner build` to generate the adapter
  // Hive.registerAdapter(BankingInfoModelAdapter());

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      // Keep the session alive — the SDK will automatically refresh the
      // access token before it expires, so users don't get kicked out.
      autoRefreshToken: true,
    ),
  );
}
