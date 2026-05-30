import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/settlement_request.dart';
import '../../providers/auth_providers.dart';
import '../../providers/balance_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/payment_providers.dart';
import '../../providers/settlement_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/debt_graph.dart';
import '../../widgets/settlement_flow_animation.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final currentUserId =
        ref.watch(authSessionProvider).valueOrNull?.user.id;
    final isCreator = ref
            .watch(groupDetailProvider(widget.groupId))
            .whenOrNull(data: (g) => g.creatorId == currentUserId) ??
        false;

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.foreground, width: 1.5)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FIcons.arrowLeft, size: 20, color: colors.foreground),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.groupName,
                      style: typo.xl2.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                  if (isCreator)
                    GestureDetector(
                      onTap: () => _confirmDelete(context, ref),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.foreground, width: 1.5),
                          color: colors.destructive,
                        ),
                        alignment: Alignment.center,
                        child: Icon(FIcons.trash2, size: 20, color: colors.foreground),
                      ),
                    ),
                ],
              ),
            ),

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.foreground, width: 1.5)),
                color: colors.card,
              ),
              child: Row(
                children: [
                  _buildTab(0, 'Ledger', colors, typo),
                  Container(width: 1.5, height: 48, color: colors.foreground),
                  _buildTab(1, 'Members', colors, typo),
                  Container(width: 1.5, height: 48, color: colors.foreground),
                  _buildTab(2, 'Requests', colors, typo),
                  Container(width: 1.5, height: 48, color: colors.foreground),
                  _buildTab(3, 'Settle', colors, typo),
                ],
              ),
            ),

            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _LedgerTab(groupId: widget.groupId),
                  _MembersTab(groupId: widget.groupId),
                  _RequestsTab(groupId: widget.groupId),
                  _SettleTab(groupId: widget.groupId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, FColors colors, FTypography typo) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          color: isSelected ? colors.primary : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: colors.foreground,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
                'Delete group',
                style: typo.lg.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently delete the group and remove all members. This cannot be undone.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await ref.read(groupRepositoryProvider).deleteGroup(widget.groupId);
                    ref.invalidate(groupListProvider);
                    // Balances and payment history between people are preserved
                    // (FK is SET NULL, not CASCADE). Invalidate so Personal tab
                    // shows fresh data after the group is gone.
                    ref.invalidate(balancesProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                  alignment: Alignment.center,
                  child: Text(
                    'Delete permanently',
                    style: typo.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: colors.foreground, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
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
  }
}

class _LedgerTab extends ConsumerWidget {
  const _LedgerTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
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
                color: colors.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load transactions',
                style: typo.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => ref.invalidate(transactionListProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.foreground, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FIcons.refreshCw, size: 16, color: colors.foreground),
                      const SizedBox(width: 8),
                      Text('Retry', style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
                    ],
                  ),
                ),
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
                  color: colors.mutedForeground,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: typo.lg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expenses added to this group will appear here',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final txn = transactions[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                            style: typo.lg.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${txn.currency} ${txn.totalAmount.toStringAsFixed(0)}',
                          style: typo.lg.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.foreground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (txn.createdAt != null)
                          Text(
                            _formatDate(txn.createdAt!),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colors.mutedForeground,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.foreground, width: 1.5),
                          ),
                          child: Text(
                            txn.status.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                        ),
                      ],
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
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
                style: typo.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => ref.invalidate(groupMembersProvider(groupId)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.foreground, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FIcons.refreshCw, size: 16, color: colors.foreground),
                      const SizedBox(width: 8),
                      Text('Retry', style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
                    ],
                  ),
                ),
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
                isCreator: isCreator,
              ),
            ),
            if (isCreator)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: GestureDetector(
                  onTap: () => _showInviteSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      border: Border.all(color: colors.foreground, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FIcons.userPlus, size: 20, color: colors.foreground),
                        const SizedBox(width: 10),
                        Text(
                          'Invite member',
                          style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMemberSheet(groupId: groupId),
    );
  }
}

class _MembersList extends ConsumerWidget {
  const _MembersList({
    required this.members,
    required this.groupId,
    required this.currentUserId,
    required this.isCreator,
  });
  final List<dynamic> members;
  final String groupId;
  final String? currentUserId;
  final bool isCreator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final ids = members.map((m) => m.userId as String).toList();
    ref.read(profileNameCacheProvider.notifier).prefetch(ids);
    final names = ref.watch(profileNameCacheProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final name = names[member.userId] ?? '...';
        final isCurrentUser = member.userId == currentUserId;
        final role = member.role == 'creator' ? 'Creator' : 'Member';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: colors.foreground, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: typo.lg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: typo.lg.copyWith(
                        fontSize: 16,
                        fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          role,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colors.mutedForeground,
                          ),
                        ),
                        if (member.status == 'pending') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.mutedForeground, width: 1),
                            ),
                            child: Text(
                              'PENDING',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isCreator && member.role != 'creator')
                GestureDetector(
                  onTap: () => _confirmRemove(context, ref, member, name,
                      colors, typo),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(FIcons.trash2,
                        size: 18, color: colors.mutedForeground),
                  ),
                )
              else if (member.joinedAt != null)
                Text(
                  _formatJoinDate(member.joinedAt!),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    dynamic member,
    String name,
    FColors colors,
    FTypography typo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: colors.foreground, width: 1.5),
        ),
        title: Text('Remove member',
            style: typo.lg
                .copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
        content: Text('Remove $name from this group?',
            style: GoogleFonts.inter(color: colors.mutedForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: typo.sm.copyWith(color: colors.mutedForeground)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remove',
                style: typo.sm.copyWith(
                    fontWeight: FontWeight.w600, color: colors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(groupRepositoryProvider).removeMember(groupId, member.userId as String);
      ref.invalidate(groupMembersProvider(groupId));
    }
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

  Future<void> _inviteMember(String userId, String name) async {
    setState(() => _adding = true);
    try {
      final groupName =
          ref.read(groupDetailProvider(widget.groupId)).valueOrNull?.name ?? '';
      await ref
          .read(groupRepositoryProvider)
          .inviteMember(widget.groupId, userId, groupName);
      ref.invalidate(groupMembersProvider(widget.groupId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invitation sent to $name')));
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

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.foreground, width: 1.5)),
      ),
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
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Invite member',
            style: typo.lg.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "They'll receive an invitation to accept or decline",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),

          // Search field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: typo.sm.copyWith(color: colors.mutedForeground.withValues(alpha: 0.5)),
                    prefixIcon: Icon(FIcons.search, size: 18, color: colors.mutedForeground),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colors.foreground, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colors.foreground, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colors.foreground, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _searching ? null : _search,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    border: Border.all(color: colors.foreground, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colors.foreground,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _searching
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: colors.foreground, strokeWidth: 2))
                      : Text(
                          'Search',
                          style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Results
          if (_results.isEmpty && !_searching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _searchController.text.length >= 2
                      ? 'No users found'
                      : 'Type at least 2 characters',
                  style: GoogleFonts.inter(fontSize: 14, color: colors.mutedForeground),
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
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border.all(color: colors.foreground, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: colors.foreground, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: typo.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                            Text(
                              id.substring(0, id.length.clamp(0, 8)),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _adding ? null : () => _inviteMember(id, name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.foreground, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FIcons.userPlus, size: 14, color: colors.foreground),
                              const SizedBox(width: 6),
                              Text('Invite', style: typo.xs.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final requestsAsync = ref.watch(groupPaymentRequestsProvider(groupId));
    final currentUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final repo = ref.watch(paymentRepositoryProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: typo.sm.copyWith(color: colors.destructive)),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FIcons.inbox, size: 48, color: colors.mutedForeground),
                const SizedBox(height: 16),
                Text('No requests yet',
                    style: typo.lg.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
                const SizedBox(height: 8),
                Text('Payment requests for this group will appear here',
                    style: GoogleFonts.inter(fontSize: 14, color: colors.mutedForeground),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final req = requests[i];
            final isReceiver = req.receiverId == currentUserId;
            final isPending = req.status == 'pending';

            Color badgeColor;
            if (req.status == 'confirmed') {
              badgeColor = colors.primary;
            } else if (req.status == 'rejected') {
              badgeColor = colors.destructive;
            } else {
              badgeColor = Colors.transparent;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ETB ${req.amount.toStringAsFixed(2)}',
                            style: typo.lg.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.foreground),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            border: Border.all(color: colors.foreground, width: 1.5),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (req.note != null && req.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        req.note!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                    if (isReceiver && isPending) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await repo.rejectPayment(req.id);
                                ref.invalidate(groupPaymentRequestsProvider(groupId));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: colors.destructive,
                                  border: Border.all(color: colors.foreground, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.foreground,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text('Reject', style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await repo.confirmPayment(req.id);
                                ref.invalidate(groupPaymentRequestsProvider(groupId));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  border: Border.all(color: colors.foreground, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.foreground,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text('Confirm', style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── _SettleTab ────────────────────────────────────────────────────────────────

class _SettleTab extends ConsumerStatefulWidget {
  const _SettleTab({required this.groupId});
  final String groupId;

  @override
  ConsumerState<_SettleTab> createState() => _SettleTabState();
}

class _SettleTabState extends ConsumerState<_SettleTab> {
  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  List<Map<String, dynamic>> _debts = [];
  Set<String> _memberIds = {};
  bool _loading = true;
  String? _error;
  final Map<String, String> _nameCache = {};
  SettlementAnim? _pendingAnim;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = ref.read(supabaseClientProvider);
      final balances = await ref
          .read(settlementRepositoryProvider)
          .getGroupNetBalances(widget.groupId);
      final membersRaw = await client
          .from('group_members')
          .select('user_id')
          .eq('group_id', widget.groupId)
          .eq('status', 'active');
      if (mounted) {
        setState(() {
          _debts = balances;
          _memberIds = (membersRaw as List)
              .map((e) => e['user_id'] as String)
              .toSet();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<String> _resolveName(String userId) async {
    if (_nameCache.containsKey(userId)) return _nameCache[userId]!;
    final client = ref.read(supabaseClientProvider);
    if (userId == client.auth.currentUser?.id) {
      _nameCache[userId] = 'You';
      return 'You';
    }
    try {
      final p = await client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final name = p?['display_name'] as String? ?? 'Unknown';
      _nameCache[userId] = name;
      return name;
    } catch (_) {
      return 'Unknown';
    }
  }

  // BFS depth-2 through Me:
  //   1-hop:  C → Me → B         (C pays B directly)
  //   2-hop:  D → C → Me → B     (D pays B directly, via C)
  // Everyone's total obligation stays the same — only who they owe changes.
  List<Map<String, dynamic>> _opportunities(String myId) {
    final owedToMe = _debts.where((d) => d['creditor_id'] == myId).toList();
    final iOwe    = _debts.where((d) => d['debtor_id']   == myId).toList();
    final result  = <Map<String, dynamic>>[];

    double _min(List<double> v) => v.reduce((a, b) => a < b ? a : b);

    for (final meDebt in iOwe) {
      final receiverId   = meDebt['creditor_id']   as String;
      final receiverName = meDebt['creditor_name'] as String;
      final meOwesB      = meDebt['amount']        as double;

      for (final theirDebt in owedToMe) {
        final cId      = theirDebt['debtor_id']   as String;
        final cName    = theirDebt['debtor_name'] as String;
        final cOwesMe  = theirDebt['amount']      as double;

        // ── 1-hop: C → Me → B ─────────────────────────────────────────────
        result.add({
          'payer_id':     cId,
          'payer_name':   cName,
          'receiver_id':  receiverId,
          'receiver_name': receiverName,
          'c_owes_me':    cOwesMe,
          'i_owe_b':      meOwesB,
          'amount':       _min([cOwesMe, meOwesB]),
          'via_id':       null,
          'via_name':     null,
          // Ordered chain of edges to reduce
          'chain': [
            {'debtor_id': cId,  'creditor_id': myId},
            {'debtor_id': myId, 'creditor_id': receiverId},
          ],
        });

        // ── 2-hop: D → C → Me → B ─────────────────────────────────────────
        final owesC = _debts.where((d) =>
            d['creditor_id'] == cId &&
            d['debtor_id']   != myId &&
            d['debtor_id']   != receiverId).toList();

        for (final dDebt in owesC) {
          final dId     = dDebt['debtor_id']   as String;
          final dName   = dDebt['debtor_name'] as String;
          final dOwesC  = dDebt['amount']      as double;
          result.add({
            'payer_id':     dId,
            'payer_name':   dName,
            'receiver_id':  receiverId,
            'receiver_name': receiverName,
            'd_owes_c':     dOwesC,
            'c_owes_me':    cOwesMe,
            'i_owe_b':      meOwesB,
            'amount':       _min([dOwesC, cOwesMe, meOwesB]),
            'via_id':       cId,
            'via_name':     cName,
            'chain': [
              {'debtor_id': dId,  'creditor_id': cId},
              {'debtor_id': cId,  'creditor_id': myId},
              {'debtor_id': myId, 'creditor_id': receiverId},
            ],
          });
        }
      }
    }
    return result;
  }

  Future<void> _confirmAndRoute(Map<String, dynamic> opp) async {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.foreground, width: 1.5),
            boxShadow: [
              BoxShadow(color: colors.foreground, offset: const Offset(6, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Confirm Routing',
                  style: typo.lg.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground)),
              const SizedBox(height: 6),
              Text(
                'Balances update immediately — no approval needed.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: colors.mutedForeground),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border.all(color: colors.foreground, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Show full chain
                    if (opp['via_name'] != null) ...[
                      _labelAmountRow(
                          '${opp['payer_name']} owes ${opp['via_name']}',
                          _fmt.format(opp['d_owes_c']), colors, typo),
                      Container(margin: const EdgeInsets.symmetric(vertical: 8), height: 1, color: colors.foreground.withValues(alpha: 0.12)),
                    ],
                    _labelAmountRow('${opp['via_name'] ?? opp['payer_name']} owes you',
                        _fmt.format(opp['c_owes_me']), colors, typo),
                    Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        color: colors.foreground.withValues(alpha: 0.12)),
                    _labelAmountRow('You owe ${opp['receiver_name']}',
                        _fmt.format(opp['i_owe_b']), colors, typo),
                    Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 1.5,
                        color: colors.foreground),
                    Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 16, color: colors.foreground),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${opp['payer_name']} → ${opp['receiver_name']}',
                            style: typo.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.foreground),
                          ),
                        ),
                        Text(
                          _fmt.format(opp['amount']),
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.foreground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    border: Border.all(color: colors.foreground, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: colors.foreground,
                          offset: const Offset(3, 3)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('Confirm',
                      style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.foreground, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('Cancel',
                      style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Pre-compute animation. For 2-hop (D→C→Me→B), C is the node
      // visible in the graph — use C as the animation "payer" anchor.
      final myId =
          ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';
      final routedAmount = (opp['amount'] as num).toDouble();
      final visiblePayerId =
          opp['via_id'] as String? ?? opp['payer_id'] as String;

      final payerMatches = _debts.where((d) =>
          d['debtor_id'] == visiblePayerId && d['creditor_id'] == myId);
      final payerCurrentAmount = payerMatches.isNotEmpty
          ? (payerMatches.first['amount'] as num).toDouble()
          : routedAmount;

      final receiverMatches = _debts.where((d) =>
          d['debtor_id'] == myId &&
          d['creditor_id'] == opp['receiver_id']);
      final receiverCurrentAmount = receiverMatches.isNotEmpty
          ? (receiverMatches.first['amount'] as num).toDouble()
          : routedAmount;

      setState(() {
        _pendingAnim = SettlementAnim(
          transitFrom: visiblePayerId,
          transitTo: opp['receiver_id'] as String,
          routedAmount: routedAmount,
          payerEdgeDebtor: visiblePayerId,
          payerEdgeCreditor: myId,
          payerNewAmount:
              (payerCurrentAmount - routedAmount).clamp(0, double.infinity),
          receiverEdgeDebtor: myId,
          receiverEdgeCreditor: opp['receiver_id'] as String,
          receiverNewAmount:
              (receiverCurrentAmount - routedAmount).clamp(0, double.infinity),
        );
      });

      // Scroll to graph so the user sees the animation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });

      // Build the chain inside the try block so any type errors are caught.
      final chain = (opp['chain'] as List<dynamic>)
          .map((e) {
            final m = e as Map;
            return <String, dynamic>{
              'debtor_id': m['debtor_id'] as String,
              'creditor_id': m['creditor_id'] as String,
            };
          })
          .toList();

      await ref.read(settlementRepositoryProvider).applyDebtRoutingChain(
            chain: chain,
            amount: routedAmount,
          );

      // Update _debts in memory so the graph is correct the moment the
      // animation ends — no loading spinner needed.
      _applyRoutingInMemory(opp['chain'] as List<dynamic>, routedAmount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt routed — balances updated')),
        );
      }
    } catch (e, st) {
      debugPrint('_confirmAndRoute error: $e\n$st');
      if (mounted) {
        setState(() => _pendingAnim = null);
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Routing failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Reduce chain edges in _debts locally so the graph is already correct
  // when the animation ends — no spinner, no flash.
  void _applyRoutingInMemory(List<dynamic> chain, double amount) {
    final updated = _debts
        .map((d) => Map<String, dynamic>.from(d))
        .toList();
    for (final edge in chain) {
      final m = edge as Map;
      final debtorId = m['debtor_id'] as String;
      final creditorId = m['creditor_id'] as String;
      final idx = updated.indexWhere(
        (d) => d['debtor_id'] == debtorId && d['creditor_id'] == creditorId,
      );
      if (idx >= 0) {
        final newAmt = (updated[idx]['amount'] as num).toDouble() - amount;
        if (newAmt <= 0) {
          updated.removeAt(idx);
        } else {
          updated[idx]['amount'] = newAmt;
        }
      }
    }
    if (mounted) setState(() => _debts = updated);
  }

  // Called by DebtGraph when the animation finishes.
  // _debts is already correct from _applyRoutingInMemory, so just clear the
  // animation and do a silent background refresh to confirm DB state.
  void _onAnimComplete() {
    if (!mounted) return;
    setState(() => _pendingAnim = null);
    _silentRefresh();
  }

  Future<void> _silentRefresh() async {
    try {
      final balances = await ref
          .read(settlementRepositoryProvider)
          .getGroupNetBalances(widget.groupId);
      if (mounted) setState(() => _debts = balances);
    } catch (_) {}
  }

  Future<void> _approveSettlement(SettlementRequest settlement) async {
    final payerName = await _resolveName(settlement.payerId);
    final receiverName = await _resolveName(settlement.receiverId);
    final initiatorName = await _resolveName(settlement.initiatorId);
    if (!mounted) return;

    final approvalFuture =
        ref.read(settlementRepositoryProvider).approveSettlement(settlement.id);

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SettlementFlowAnimation(
          payerName: payerName,
          receiverName: receiverName,
          initiatorName: initiatorName,
          amount: settlement.amount,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

    try {
      await approvalFuture;
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectSettlement(String id) async {
    try {
      await ref.read(settlementRepositoryProvider).rejectSettlement(id);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final myId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';

    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FIcons.circleAlert, size: 40, color: colors.destructive),
              const SizedBox(height: 12),
              Text(_error!,
                  style: typo.sm.copyWith(color: colors.mutedForeground),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.foreground, width: 1.5),
                  ),
                  child: Text('Retry',
                      style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final opps = _opportunities(myId);
    final settlementsAsync = ref.watch(settlementRequestsProvider);
    final pendingApprovals = settlementsAsync.whenOrNull(
          data: (list) => list
              .where((s) =>
                  s.status == 'pending' &&
                  s.payerId == myId &&
                  _memberIds.contains(s.initiatorId) &&
                  _memberIds.contains(s.receiverId))
              .toList(),
        ) ??
        [];

    final isEmpty =
        _debts.isEmpty && opps.isEmpty && pendingApprovals.isEmpty;

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        children: [
          if (isEmpty) ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      size: 48, color: colors.mutedForeground),
                  const SizedBox(height: 16),
                  Text('All settled up',
                      style: typo.lg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground)),
                  const SizedBox(height: 8),
                  Text('No debts between group members',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: colors.mutedForeground)),
                ],
              ),
            ),
          ],

          if (_debts.isNotEmpty) ...[
            _sectionLabel('GROUP DEBTS', colors),
            const SizedBox(height: 12),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: colors.foreground, offset: const Offset(3, 3)),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: DebtGraph(
                debts: _debts,
                myId: myId,
                pending: _pendingAnim,
                onAnimationComplete: _onAnimComplete,
              ),
            ),
            const SizedBox(height: 32),
          ],

          if (opps.isNotEmpty) ...[
            _sectionLabel('ROUTING OPPORTUNITIES', colors),
            const SizedBox(height: 6),
            Text(
              'Redirect a debt — ask someone who owes you to pay who you owe',
              style: GoogleFonts.inter(
                  fontSize: 12, color: colors.mutedForeground),
            ),
            const SizedBox(height: 14),
            ...opps.map((o) => _opportunityCard(o, colors, typo)),
            const SizedBox(height: 32),
          ],

          if (pendingApprovals.isNotEmpty) ...[
            _sectionLabel('PENDING YOUR APPROVAL', colors),
            const SizedBox(height: 12),
            ...pendingApprovals
                .map((s) => _pendingSettlementTile(s, colors, typo)),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, FColors colors) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: colors.mutedForeground,
        ),
      );

  Widget _opportunityCard(
      Map<String, dynamic> opp, FColors colors, FTypography typo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.foreground, width: 1.5),
        boxShadow: [
          BoxShadow(color: colors.foreground, offset: const Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary,
              border: Border(
                  bottom: BorderSide(color: colors.foreground, width: 1.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded,
                    size: 16, color: colors.foreground),
                const SizedBox(width: 8),
                Text(
                  'DEBT ROUTE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: colors.foreground,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (opp['via_name'] != null) ...[
                  _labelAmountRow(
                      '${opp['payer_name']} owes ${opp['via_name']}',
                      _fmt.format(opp['d_owes_c']), colors, typo),
                  const SizedBox(height: 6),
                ],
                _labelAmountRow(
                    '${opp['via_name'] ?? opp['payer_name']} owes you',
                    _fmt.format(opp['c_owes_me']), colors, typo),
                const SizedBox(height: 6),
                _labelAmountRow('You owe ${opp['receiver_name']}',
                    _fmt.format(opp['i_owe_b']), colors, typo),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 1.5,
                  color: colors.foreground.withValues(alpha: 0.2),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        opp['via_name'] != null
                            ? '${opp['payer_name']} → ${opp['receiver_name']} via ${opp['via_name']}'
                            : '${opp['payer_name']} → ${opp['receiver_name']} directly',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: colors.mutedForeground),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _fmt.format(opp['amount']),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _pendingAnim == null ? () => _confirmAndRoute(opp) : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: colors.foreground,
                border: Border(
                    top: BorderSide(color: colors.foreground, width: 1.5)),
              ),
              alignment: Alignment.center,
              child: Text(
                'ROUTE IT',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: colors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingSettlementTile(
      SettlementRequest s, FColors colors, FTypography typo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.foreground, width: 1.5),
        boxShadow: [
          BoxShadow(color: colors.foreground, offset: const Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay ${_fmt.format(s.amount)} directly',
                  style: typo.lg.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _resolveName(s.initiatorId),
                  builder: (_, snap) => Text(
                    'Requested by ${snap.data ?? '...'}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: colors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 2),
                FutureBuilder<String>(
                  future: _resolveName(s.receiverId),
                  builder: (_, snap) => Text(
                    'To: ${snap.data ?? '...'}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: colors.mutedForeground),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1.5, color: colors.foreground),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _rejectSettlement(s.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.destructive,
                      border: Border(
                          right: BorderSide(
                              color: colors.foreground, width: 1.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text('Decline',
                        style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground)),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _approveSettlement(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: colors.primary,
                    alignment: Alignment.center,
                    child: Text('Approve & Pay',
                        style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelAmountRow(
      String label, String amount, FColors colors, FTypography typo) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: colors.mutedForeground)),
        ),
        Text(
          amount,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.foreground),
        ),
      ],
    );
  }
}
