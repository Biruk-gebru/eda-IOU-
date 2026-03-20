import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../controllers/auth_controller.dart';
import '../../providers/user_providers.dart';
import '../setup/bank_info_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailDigests = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typo = theme.typography;
    final userAsync = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Settings',
            style: typo.lg
                .copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
        const SizedBox(height: 20),

        // Profile card
        userAsync.when(
          data: (user) {
            final name = user?.displayName ?? 'Your profile';
            final email = user?.email ?? '';
            final initial =
                name.isNotEmpty ? name[0].toUpperCase() : '?';

            return FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: typo.lg.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: typo.md.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground)),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(email,
                                style: typo.xs
                                    .copyWith(color: colors.mutedForeground)),
                          ],
                        ],
                      ),
                    ),
                    Icon(FIcons.chevronRight,
                        size: 18, color: colors.mutedForeground),
                  ],
                ),
              ),
            );
          },
          loading: () => FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Loading...',
                      style: typo.sm.copyWith(color: colors.mutedForeground)),
                ],
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // Notifications
        _label(typo, colors, 'Notifications'),
        const SizedBox(height: 8),
        FCard.raw(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                FSwitch(
                  label: const Text('Push notifications'),
                  description: const Text('Approvals, payments, reminders'),
                  value: _pushNotifications,
                  onChange: (v) => setState(() => _pushNotifications = v),
                ),
                const SizedBox(height: 8),
                const FDivider(),
                const SizedBox(height: 8),
                FSwitch(
                  label: const Text('Email digests'),
                  description: const Text('Daily summary of activity'),
                  value: _emailDigests,
                  onChange: (v) => setState(() => _emailDigests = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Account
        _label(typo, colors, 'Account'),
        const SizedBox(height: 8),
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FIcons.userPen),
              title: const Text('Edit profile'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () {},
            ),
            FTile(
              prefix: const Icon(FIcons.landmark),
              title: const Text('Banking info'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BankInfoScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Support
        _label(typo, colors, 'Support'),
        const SizedBox(height: 8),
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FIcons.lifeBuoy),
              title: const Text('Help center'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () {},
            ),
            FTile(
              prefix: const Icon(FIcons.info),
              title: const Text('About'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Sign out
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () => _confirmSignOut(context),
          prefix: const Icon(FIcons.logOut),
          child: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _label(FTypography typo, FColors colors, String text) => Text(
        text,
        style: typo.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
          letterSpacing: 0.5,
        ),
      );

  Future<void> _confirmSignOut(BuildContext context) async {
    await showFDialog(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('Sign out'),
        body: const Text('Are you sure you want to sign out?'),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(authControllerProvider).signOut();
              } on AuthControllerException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('Sign out'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
