import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/auth_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/transaction_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FScaffold(
      header: FHeader.nested(
        title: Text(groupName),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(FIcons.trash2),
            onPress: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      childPad: false,
      child: FTabs(
        expands: true,
        children: [
          FTabEntry(
            label: const Text('Ledger'),
            child: Expanded(
              child: _LedgerTab(groupId: groupId),
            ),
          ),
          FTabEntry(
            label: const Text('Members'),
            child: Expanded(
              child: _MembersTab(groupId: groupId),
            ),
          ),
          FTabEntry(
            label: const Text('Requests'),
            child: Expanded(
              child: _RequestsTab(groupId: groupId),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await showFDialog(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('Delete group'),
        body: const Text(
            'This will permanently delete the group and remove all members. This cannot be undone.'),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(groupRepositoryProvider).deleteGroup(groupId);
                ref.invalidate(groupListProvider);
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete'),
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

class _LedgerTab extends ConsumerWidget {
  const _LedgerTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return transactionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FIcons.triangleAlert,
                size: 40,
                color: context.theme.colors.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load transactions',
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 12),
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => ref.invalidate(transactionListProvider),
                prefix: const Icon(FIcons.refreshCw),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (allTransactions) {
        final transactions = allTransactions
            .where((t) => t.groupId == groupId)
            .toList();

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FIcons.receipt,
                  size: 48,
                  color: context.theme.colors.mutedForeground,
                ),
                const SizedBox(height: 12),
                Text(
                  'No transactions yet',
                  style: context.theme.typography.lg.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expenses added to this group will appear here',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final txn = transactions[index];

            return FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            txn.description ?? 'Untitled expense',
                            style: context.theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${txn.currency} ${txn.totalAmount.toStringAsFixed(0)}',
                          style: context.theme.typography.sm.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (txn.createdAt != null)
                      Text(
                        _formatDate(txn.createdAt!),
                        style: context.theme.typography.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    const SizedBox(height: 8),
                    FBadge(
                      variant: FBadgeVariant.outline,
                      child: Text(txn.status),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today \u2022 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday \u2022 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day} \u2022 '
          '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final sessionAsync = ref.watch(authSessionProvider);
    final currentUserId = sessionAsync.valueOrNull?.user.id;

    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final isCreator = groupAsync.whenOrNull(
          data: (group) => group.creatorId == currentUserId,
        ) ??
        false;

    return membersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load members',
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 12),
              FButton(
                variant: FButtonVariant.outline,
                onPress: () =>
                    ref.invalidate(groupMembersProvider(groupId)),
                prefix: const Icon(FIcons.refreshCw),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (members) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isCurrentUser = member.userId == currentUserId;
                  final roleLabel = member.role == 'creator'
                      ? 'Creator'
                      : 'Member';

                  return FTile(
                    prefix: FAvatar.raw(
                      size: 36,
                      child: Text(
                        isCurrentUser
                            ? 'Y'
                            : member.userId.characters.first.toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    title: Text(isCurrentUser ? 'You' : member.userId),
                    subtitle: Text(roleLabel),
                    suffix: Text(
                      member.joinedAt != null
                          ? 'Joined ${_formatJoinDate(member.joinedAt!)}'
                          : '',
                      style: context.theme.typography.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isCreator)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FButton(
                  onPress: () => _showInviteSheet(context),
                  prefix: const Icon(FIcons.userPlus),
                  child: const Text('Add member'),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatJoinDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invite via link',
              style: context.theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'https://eda.app/invite/$groupId',
                        style: context.theme.typography.sm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FButton.icon(
                      onPress: () {
                        Clipboard.setData(ClipboardData(
                            text: 'https://eda.app/invite/$groupId'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied')),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Icon(FIcons.copy),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FButton(
              onPress: () => Navigator.of(sheetContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder — will be backed by a payment request provider later.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.inbox,
            size: 48,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(height: 12),
          Text(
            'No requests yet',
            style: context.theme.typography.lg.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Payment requests for this group will appear here',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
