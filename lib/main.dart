import 'package:flutter/material.dart';
import 'src/core/di/di.dart';
import 'src/presentation/app.dart';

export 'src/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const MyApp());
}
