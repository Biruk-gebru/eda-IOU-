import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_providers.dart';
import '../profile/edit_profile_screen.dart';
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final userAsync = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Text('Settings',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            )),
        const SizedBox(height: 24),

        // ── Profile card ──────────────────────────────────────────────────
        userAsync.when(
          data: (user) {
            final name = user?.displayName ?? 'Set up your profile';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            final hasBanking = user?.accountNumber != null &&
                (user?.accountNumber?.isNotEmpty ?? false);
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              child: FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(initial,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            )),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: typo.md.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              hasBanking
                                  ? 'Banking info added'
                                  : 'Tap to edit profile & banking',
                              style: typo.xs.copyWith(color: colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      Icon(FIcons.chevronRight, size: 16, color: colors.border),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(width: 54, height: 54,
                      decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle)),
                  const SizedBox(width: 14),
                  Text('Loading…', style: typo.sm.copyWith(color: colors.mutedForeground)),
                ],
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 28),

        // ── Appearance ────────────────────────────────────────────────────
        _sectionLabel('APPEARANCE', colors, typo),
        const SizedBox(height: 10),
        _themeSelector(ref, colors, typo),

        const SizedBox(height: 28),

        // ── Notifications ─────────────────────────────────────────────────
        _sectionLabel('NOTIFICATIONS', colors, typo),
        const SizedBox(height: 10),
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

        const SizedBox(height: 28),

        // ── Account ────────────────────────────────────────────────────────
        _sectionLabel('ACCOUNT', colors, typo),
        const SizedBox(height: 10),
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FIcons.userPen),
              title: const Text('Edit profile'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            FTile(
              prefix: const Icon(FIcons.landmark),
              title: const Text('Banking info'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const BankInfoScreen())),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Support ────────────────────────────────────────────────────────
        _sectionLabel('SUPPORT', colors, typo),
        const SizedBox(height: 10),
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

        const SizedBox(height: 36),

        // ── Sign out ───────────────────────────────────────────────────────
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () => _confirmSignOut(context),
          prefix: const Icon(FIcons.logOut),
          child: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _themeSelector(WidgetRef ref, FColors colors, FTypography typo) {
    final current = ref.watch(themeModeProvider);

    Widget chip(AppThemeMode mode, String label, IconData icon) {
      final selected = current == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).state = mode,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.card : colors.secondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? colors.foreground.withValues(alpha: 0.3) : colors.border,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18,
                    color: selected ? colors.foreground : colors.mutedForeground),
                const SizedBox(height: 4),
                Text(label,
                    style: typo.xs.copyWith(
                      color: selected ? colors.foreground : colors.mutedForeground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(AppThemeMode.system, 'System', FIcons.monitor),
        const SizedBox(width: 8),
        chip(AppThemeMode.light, 'Light', FIcons.sun),
        const SizedBox(width: 8),
        chip(AppThemeMode.dark, 'Dark', FIcons.moon),
      ],
    );
  }

  Widget _sectionLabel(String text, FColors colors, FTypography typo) => Text(
        text,
        style: typo.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
          letterSpacing: 0.8,
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
