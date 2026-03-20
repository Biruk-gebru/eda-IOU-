import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/connectivity_provider.dart';
import 'providers/auth_providers.dart';
import 'screens/auth/offline_login_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/main_shell.dart';
import 'screens/setup/bank_info_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Eda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5), // Teal accent
          primary: const Color(0xFF00BFA5),
          secondary: const Color(0xFF6C63FF), // Purple accent
          surface: Colors.grey[50],
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final connectivityAsync = ref.watch(connectivityProvider);

    return sessionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'We ran into an issue while checking your session.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => ref.refresh(authSessionProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (session) {
        if (session != null) {
          final user = session.user;
          final metadata = user.userMetadata;
          final hasBankInfo = metadata?['has_bank_info'] == true;

          if (!hasBankInfo) {
            return const BankInfoScreen();
          }

          return const MainShell();
        }

        return connectivityAsync.when(
          data: (results) {
            final isOffline = results.contains(ConnectivityResult.none);
            if (isOffline) {
              return const OfflineLoginScreen();
            }
            return const SignInScreen();
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SignInScreen(), // Fallback
        );
      },
    );
  }
}
