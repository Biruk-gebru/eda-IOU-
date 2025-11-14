import 'package:flutter/material.dart';
import 'src/core/di/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eda',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 58, 183, 146)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Eda - Setup Complete')),
      ),
    );
  }
}
