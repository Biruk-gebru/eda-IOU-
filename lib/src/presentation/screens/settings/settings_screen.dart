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
    final userAsync = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Profile card
        _buildProfileCard(context, userAsync),
        const SizedBox(height: 28),

        // Notifications section
        _sectionLabel(context, 'Notifications'),
        const SizedBox(height: 8),
        FCard.raw(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: FSwitch(
                    label: const Text('Push notifications'),
                    description: const Text('Approvals, payments, reminders'),
                    value: _pushNotifications,
                    onChange: (value) =>
                        setState(() => _pushNotifications = value),
                  ),
                ),
                const FDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: FSwitch(
                    label: const Text('Email digests'),
                    description: const Text('Daily summary of activity'),
                    value: _emailDigests,
                    onChange: (value) =>
                        setState(() => _emailDigests = value),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Account section
        _sectionLabel(context, 'Account'),
        const SizedBox(height: 8),
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FIcons.userPen),
              title: const Text('Edit profile'),
              subtitle: const Text('Name, avatar, preferences'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () {},
            ),
            FTile(
              prefix: const Icon(FIcons.landmark),
              title: const Text('Banking info'),
              subtitle: const Text('Payment accounts'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BankInfoScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Support section
        _sectionLabel(context, 'Support'),
        const SizedBox(height: 8),
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FIcons.lifeBuoy),
              title: const Text('Help center'),
              subtitle: const Text('FAQs, guides, troubleshooting'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () {},
            ),
            FTile(
              prefix: const Icon(FIcons.info),
              title: const Text('About'),
              subtitle: const Text('Version, licenses, credits'),
              suffix: const Icon(FIcons.chevronRight),
              onPress: () {},
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Sign out button
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () => _confirmSignOut(context),
          prefix: const Icon(FIcons.logOut),
          child: const Text('Sign out'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AsyncValue<dynamic> userAsync,
  ) {
    return userAsync.when(
      data: (user) {
        final displayName = user?.displayName ?? 'Your profile';
        final email = user?.email ?? 'you@example.com';
        final initials = displayName.isNotEmpty
            ? displayName.substring(0, 1).toUpperCase()
            : '?';

        return FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FAvatar.raw(
                  size: 56,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
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
              FAvatar.raw(size: 56, child: const Text('...')),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loading...'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FAvatar.raw(size: 56, child: const Text('?')),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unable to load profile'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    await showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('Sign out'),
        body: const Text('Are you sure you want to sign out?'),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () async {
              Navigator.of(dialogContext).pop();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(authControllerProvider).signOut();
              } on AuthControllerException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            child: const Text('Sign out'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
