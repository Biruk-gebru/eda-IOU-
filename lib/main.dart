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
  await initializeDependencies();
  await LocalNotificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}
