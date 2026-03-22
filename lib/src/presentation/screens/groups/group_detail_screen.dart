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
            child: _LedgerTab(groupId: groupId),
          ),
          FTabEntry(
            label: const Text('Members'),
            child: _MembersTab(groupId: groupId),
          ),
          FTabEntry(
            label: const Text('Requests'),
            child: _RequestsTab(groupId: groupId),
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
              child: _MembersList(
                members: members,
                groupId: groupId,
                currentUserId: currentUserId,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddMemberSheet(groupId: groupId),
    );
  }
}

class _MembersList extends ConsumerStatefulWidget {
  const _MembersList({
    required this.members,
    required this.groupId,
    required this.currentUserId,
  });
  final List<dynamic> members;
  final String groupId;
  final String? currentUserId;

  @override
  ConsumerState<_MembersList> createState() => _MembersListState();
}

class _MembersListState extends ConsumerState<_MembersList> {
  final Map<String, String> _names = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchNames();
  }

  Future<void> _fetchNames() async {
    try {
      final client = ref.read(supabaseClientProvider);
      for (final member in widget.members) {
        if (member.userId == widget.currentUserId) {
          _names[member.userId] = 'You';
          continue;
        }
        try {
          final profile = await client
              .from('profiles')
              .select('display_name')
              .eq('id', member.userId)
              .maybeSingle();
          _names[member.userId] =
              profile?['display_name'] as String? ?? 'Unknown';
        } catch (_) {
          _names[member.userId] = 'Unknown';
        }
      }
      if (mounted) setState(() => _loaded = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.members.length,
      itemBuilder: (context, index) {
        final member = widget.members[index];
        final name = _names[member.userId] ?? ((_loaded) ? 'Unknown' : '...');
        final isCurrentUser = member.userId == widget.currentUserId;
        final role = member.role == 'creator' ? 'Creator' : 'Member';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return FTile(
          prefix: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: typo.xs.copyWith(
                    fontWeight: FontWeight.w600, color: colors.foreground)),
          ),
          title: Text(name,
              style: typo.sm.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                  color: colors.foreground)),
          subtitle: Text(role,
              style: typo.xs.copyWith(color: colors.mutedForeground)),
          suffix: member.joinedAt != null
              ? Text(_formatJoinDate(member.joinedAt!),
                  style: typo.xs.copyWith(color: colors.mutedForeground))
              : null,
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
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet({required this.groupId});
  final String groupId;

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _adding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _searching = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final currentUserId = client.auth.currentUser?.id;

      // Search by display_name (case-insensitive)
      final data = await client
          .from('profiles')
          .select('id, display_name')
          .ilike('display_name', '%$query%')
          .neq('id', currentUserId ?? '')
          .limit(10);

      // Filter out existing members
      final members =
          await ref.read(groupMembersProvider(widget.groupId).future);
      final memberIds = members.map((m) => m.userId).toSet();

      setState(() {
        _results = (data as List)
            .where((p) => !memberIds.contains(p['id']))
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addMember(String userId, String name) async {
    setState(() => _adding = true);
    try {
      await ref
          .read(groupRepositoryProvider)
          .addMember(widget.groupId, userId);
      ref.invalidate(groupMembersProvider(widget.groupId));

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$name added')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add member',
              style: typo.lg
                  .copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
          const SizedBox(height: 4),
          Text('Search by name to add someone to this group',
              style: typo.sm.copyWith(color: colors.mutedForeground)),
          const SizedBox(height: 16),

          // Search field
          Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(
                      controller: _searchController),
                  hint: 'Search by name...',
                  prefixBuilder: (ctx, style, variants) =>
                      FTextField.prefixIconBuilder(
                          ctx, style, variants, const Icon(FIcons.search)),
                ),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: _searching ? null : _search,
                child: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2))
                    : const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Results
          if (_results.isEmpty && !_searching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  _searchController.text.length >= 2
                      ? 'No users found'
                      : 'Type at least 2 characters',
                  style: typo.xs.copyWith(color: colors.mutedForeground),
                ),
              ),
            )
          else
            ...List.generate(
              _results.length > 5 ? 5 : _results.length,
              (i) {
                final user = _results[i];
                final name = user['display_name'] as String? ?? 'Unknown';
                final id = user['id'] as String;
                final initial =
                    name.isNotEmpty ? name[0].toUpperCase() : '?';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FTile(
                    prefix: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: typo.xs.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.foreground)),
                    ),
                    title: Text(name),
                    subtitle: Text(id.substring(0, id.length.clamp(0, 8)),
                        style: typo.xs
                            .copyWith(color: colors.mutedForeground)),
                    suffix: FButton(
                      onPress: _adding
                          ? null
                          : () => _addMember(id, name),
                      prefix: const Icon(FIcons.userPlus),
                      child: const Text('Add'),
                    ),
                  ),
                );
              },
            ),
        ],
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
