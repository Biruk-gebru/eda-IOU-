import 'package:flutter/material.dart';
import 'screens/main_shell.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5), // Teal accent
          primary: const Color(0xFF00BFA5),
          secondary: const Color(0xFF6C63FF), // Purple accent
          background: Colors.grey[50],
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default, but explicit is good
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}
