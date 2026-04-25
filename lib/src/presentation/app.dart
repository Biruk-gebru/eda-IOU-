import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers/connectivity_provider.dart';
import 'providers/auth_providers.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/main_shell.dart';

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
    final typo = context.theme.typography;

    return sessionAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      ),
      error: (error, _) {
        final isOffline = connectivityAsync.whenOrNull(
              data: (r) => r.contains(ConnectivityResult.none),
            ) ??
            false;
        if (isOffline) return const MainShell();

        return Scaffold(
          backgroundColor: colors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.destructive,
                      border: Border.all(color: colors.foreground, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(FIcons.circleAlert, color: colors.foreground, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session Error',
                                style: typo.sm.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.foreground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                error.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: colors.foreground,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => ref.refresh(authSessionProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      child: Text(
                        'Retry',
                        style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (session) {
        if (session != null) {
          final metadata = session.user.userMetadata;
          final hasCompletedSetup = metadata?['has_bank_info'] == true;

          // New user — needs to set display name first
          if (!hasCompletedSetup) return const OnboardingScreen();

          return const MainShell();
        }

        // No session
        final isOffline = connectivityAsync.whenOrNull(
              data: (r) => r.contains(ConnectivityResult.none),
            ) ??
            false;
        if (isOffline) return const MainShell();

        return const SignInScreen();
      },
    );
  }
}
