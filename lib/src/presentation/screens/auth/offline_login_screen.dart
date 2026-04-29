import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/neo_button.dart';

class OfflineLoginScreen extends ConsumerWidget {
  const OfflineLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return Scaffold(
      backgroundColor: colors.background, // Paper background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.foreground,
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    FIcons.wifiOff,
                    size: 48,
                    color: colors.foreground,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'You are offline',
                    style: typo.xl3.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We cannot log you in while you are offline. Please check your internet connection and try again.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colors.mutedForeground,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  NeoButton(
                    onTap: () => ref.refresh(authSessionProvider),
                    backgroundColor: colors.primary,
                    borderColor: colors.foreground,
                    shadowOffset: 3.0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FIcons.refreshCw, size: 18, color: colors.foreground),
                        const SizedBox(width: 8),
                        Text(
                          'Retry Connection',
                          style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
