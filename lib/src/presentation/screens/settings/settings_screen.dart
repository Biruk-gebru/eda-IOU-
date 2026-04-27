import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/local_notification_service.dart';
import '../../controllers/auth_controller.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_providers.dart';
import '../profile/edit_profile_screen.dart';
import '../setup/bank_info_screen.dart';
import '../../widgets/neo_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailDigests = false;

  @override
  void initState() {
    super.initState();
    LocalNotificationService.isEnabled().then((v) {
      if (mounted) setState(() => _pushNotifications = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
          children: [
            Text(
              'Settings',
              style: typo.xl2.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
                letterSpacing: -0.28,
              ),
            ),
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      border: Border.all(color: colors.foreground, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: colors.foreground, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: typo.xl3.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: typo.lg.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasBanking
                                    ? 'Banking info added'
                                    : 'Tap to edit profile & banking',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(FIcons.chevronRight, size: 20, color: colors.foreground),
                      ],
                    ),
                  ),
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.foreground, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(width: 54, height: 54, decoration: BoxDecoration(border: Border.all(color: colors.foreground, width: 1.5))),
                    const SizedBox(width: 14),
                    Text('Loading…', style: GoogleFonts.inter(color: colors.mutedForeground)),
                  ],
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            // ── Appearance ────────────────────────────────────────────────────
            _sectionLabel('APPEARANCE', colors, typo),
            const SizedBox(height: 12),
            _themeSelector(ref, colors, typo),

            const SizedBox(height: 32),

            // ── Notifications ─────────────────────────────────────────────────
            _sectionLabel('NOTIFICATIONS', colors, typo),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.foreground,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    'Push notifications',
                    'Approvals, payments, reminders',
                    _pushNotifications,
                    (v) async {
                      setState(() => _pushNotifications = v);
                      await LocalNotificationService.setEnabled(v);
                      if (v) await LocalNotificationService.requestPermission();
                    },
                    colors,
                    typo,
                  ),
                  Container(height: 1.5, color: colors.foreground),
                  _buildSwitchRow(
                    'Email digests',
                    'Daily summary of activity',
                    _emailDigests,
                    (v) => setState(() => _emailDigests = v),
                    colors,
                    typo,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Account ────────────────────────────────────────────────────────
            _sectionLabel('ACCOUNT', colors, typo),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.foreground,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionRow(
                    'Edit profile',
                    FIcons.userPen,
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    colors,
                    typo,
                  ),
                  Container(height: 1.5, color: colors.foreground),
                  _buildActionRow(
                    'Banking info',
                    FIcons.landmark,
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BankInfoScreen())),
                    colors,
                    typo,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Support ────────────────────────────────────────────────────────
            _sectionLabel('SUPPORT', colors, typo),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.foreground,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionRow('Help center', FIcons.lifeBuoy, () {}, colors, typo),
                  Container(height: 1.5, color: colors.foreground),
                  _buildActionRow('About', FIcons.info, () {}, colors, typo),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Danger zone ─────────────────────────────────────────────────
            _sectionLabel('DANGER ZONE', colors, typo),
            const SizedBox(height: 12),
            NeoButton(
              onTap: () => _confirmSignOut(context),
              backgroundColor: Colors.transparent,
              borderColor: colors.foreground,
              shadowOffset: 0.0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FIcons.logOut, size: 18, color: colors.foreground),
                  const SizedBox(width: 8),
                  Text(
                    'Sign out',
                    style: typo.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NeoButton(
              onTap: () => _confirmDeleteAccount(context),
              backgroundColor: colors.destructive,
              borderColor: colors.foreground,
              shadowOffset: 3.0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FIcons.trash2, size: 18, color: colors.foreground),
                  const SizedBox(width: 8),
                  Text(
                    'Delete account',
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
    );
  }

  Widget _buildSwitchRow(String label, String description, bool value, ValueChanged<bool> onChanged, FColors colors, FTypography typo) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: typo.lg.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Brutalist Switch
            Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value ? colors.primary : Colors.transparent,
                border: Border.all(color: colors.foreground, width: 1.5),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: colors.foreground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(String label, IconData icon, VoidCallback onTap, FColors colors, FTypography typo) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.foreground),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: typo.lg.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ),
            Icon(FIcons.chevronRight, size: 20, color: colors.foreground),
          ],
        ),
      ),
    );
  }

  Widget _themeSelector(WidgetRef ref, FColors colors, FTypography typo) {
    final current = ref.watch(themeModeProvider);

    Widget chip(AppThemeMode mode, String label, IconData icon) {
      final selected = current == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).state = mode,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? colors.card : Colors.transparent,
              border: Border.all(
                color: colors.foreground,
                width: 1.5,
              ),
              boxShadow: selected ? [
                BoxShadow(
                  color: colors.foreground,
                  offset: const Offset(3, 3),
                )
              ] : null,
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: colors.foreground),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: typo.sm.copyWith(
                    color: colors.foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(AppThemeMode.system, 'System', FIcons.monitor),
        const SizedBox(width: 12),
        chip(AppThemeMode.light, 'Light', FIcons.sun),
        const SizedBox(width: 12),
        chip(AppThemeMode.dark, 'Dark', FIcons.moon),
      ],
    );
  }

  Widget _sectionLabel(String text, FColors colors, FTypography typo) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: colors.mutedForeground,
        ),
      );

  Future<void> _confirmSignOut(BuildContext context) async {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.background,
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
              Text(
                'Sign out',
                style: typo.lg.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 28),
              NeoButton(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await ref.read(authControllerProvider).signOut();
                  } on AuthControllerException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
                backgroundColor: colors.destructive,
                borderColor: colors.foreground,
                shadowOffset: 3.0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Sign out',
                  style: typo.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NeoButton(
                onTap: () => Navigator.of(ctx).pop(),
                backgroundColor: Colors.transparent,
                borderColor: colors.foreground,
                shadowOffset: 0.0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Cancel',
                  style: typo.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.background,
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
              Text(
                'Delete account',
                style: typo.lg.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete your account, all your data, groups, and transaction history. This cannot be undone.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 28),
              NeoButton(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await ref.read(authControllerProvider).deleteAccount();
                  } on AuthControllerException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
                backgroundColor: colors.destructive,
                borderColor: colors.foreground,
                shadowOffset: 3.0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Delete permanently',
                  style: typo.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NeoButton(
                onTap: () => Navigator.of(ctx).pop(),
                backgroundColor: Colors.transparent,
                borderColor: colors.foreground,
                shadowOffset: 0.0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Cancel',
                  style: typo.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
