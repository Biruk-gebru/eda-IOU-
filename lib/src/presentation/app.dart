import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../core/providers/connectivity_provider.dart';
import 'providers/auth_providers.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/offline_login_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/main_shell.dart';
import 'screens/setup/bank_info_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final themeData = resolveTheme(mode, brightness);

    return MaterialApp(
      title: 'Eda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      builder: (context, child) => FTheme(
        data: themeData,
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
    final colors = context.theme.colors;

    return sessionAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
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

          if (!hasBankInfo) return const BankInfoScreen();
          return const MainShell();
        }

        return connectivityAsync.when(
          data: (results) {
            final isOffline = results.contains(ConnectivityResult.none);
            if (isOffline) return const OfflineLoginScreen();
            return const SignInScreen();
          },
          loading: () => Scaffold(
            backgroundColor: colors.background,
            body: Center(
                child: CircularProgressIndicator(color: colors.primary)),
          ),
          error: (_, __) => const SignInScreen(),
        );
      },
    );
  }
}
