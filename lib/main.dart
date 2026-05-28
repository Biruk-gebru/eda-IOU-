import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/di/di.dart';
import 'src/core/services/local_notification_service.dart';
import 'src/presentation/app.dart';

export 'src/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final url = dotenv.maybeGet('SUPABASE_URL');
  final key = dotenv.maybeGet('SUPABASE_ANON_KEY');
  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    runApp(const _EnvErrorApp());
    return;
  }

  await initializeDependencies();
  await LocalNotificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class _EnvErrorApp extends StatelessWidget {
  const _EnvErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Missing .env configuration.\nCopy .env.example to .env and fill in your Supabase credentials.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
