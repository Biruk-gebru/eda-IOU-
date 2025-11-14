import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';


Future<void> initializeDependencies() async {
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
}
