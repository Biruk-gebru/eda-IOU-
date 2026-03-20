import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light.touch,
        child: child!,
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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => FScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FAlert(
                  variant: FAlertVariant.destructive,
                  title: const Text('Session Error'),
                  subtitle: Text(error.toString()),
                ),
                const SizedBox(height: 24),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => ref.refresh(authSessionProvider),
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
            if (isOffline) return const OfflineLoginScreen();
            return const SignInScreen();
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SignInScreen(),
        );
      },
    );
  }
}
