import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/settlement_request.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settlement_providers.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  static final _fmt = NumberFormat.currency(symbol: 'ETB ');
  final Map<String, String> _nameCache = {};

  Future<String> _resolveName(String userId) async {
    if (_nameCache.containsKey(userId)) return _nameCache[userId]!;
    try {
      final client = ref.read(supabaseClientProvider);
      if (userId == client.auth.currentUser?.id) {
        _nameCache[userId] = 'You';
        return 'You';
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typo = theme.typography;
    final settlementsAsync = ref.watch(settlementRequestsProvider);
    final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Settlements'),
        prefixes: [
          FHeaderAction(
            icon: const Icon(FIcons.chevronLeft),
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: settlementsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FIcons.circleAlert, size: 40, color: colors.destructive),
              const SizedBox(height: 12),
              Text('Failed to load settlements',
                  style: typo.sm.copyWith(color: colors.destructive)),
            ],
          ),
        ),
        data: (settlements) {
          if (settlements.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FIcons.arrowRightLeft,
                      size: 48, color: colors.mutedForeground),
                  const SizedBox(height: 12),
                  Text('No settlement requests yet',
                      style:
                          typo.sm.copyWith(color: colors.mutedForeground)),
                ],
              ),
            );
          }

          final pending =
              settlements.where((s) => s.status == 'pending').toList();
          final approved =
              settlements.where((s) => s.status == 'approved').toList();
          final completed = settlements
              .where((s) =>
                  s.status == 'completed' || s.status == 'rejected')
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionLabel(typo, colors, 'Pending'),
                const SizedBox(height: 8),
                ...pending.map((s) => _settlementTile(s, userId, colors, typo)),
                const SizedBox(height: 20),
              ],
              if (approved.isNotEmpty) ...[
                _sectionLabel(typo, colors, 'Approved'),
                const SizedBox(height: 8),
                ...approved.map((s) => _settlementTile(s, userId, colors, typo)),
                const SizedBox(height: 20),
              ],
              if (completed.isNotEmpty) ...[
                _sectionLabel(typo, colors, 'Completed / Rejected'),
                const SizedBox(height: 8),
                ...completed.map((s) => _settlementTile(s, userId, colors, typo)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(FTypography typo, FColors colors, String text) {
    return Text(
      text,
      style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground),
    );
  }

  FBadgeVariant _badgeVariant(String status) {
    switch (status) {
      case 'approved':
      case 'completed':
        return FBadgeVariant.primary;
      case 'rejected':
        return FBadgeVariant.destructive;
      default:
        return FBadgeVariant.outline;
    }
  }

  Widget _settlementTile(
    SettlementRequest settlement,
    String? userId,
    FColors colors,
    FTypography typo,
  ) {
    final isPayer = settlement.payerId == userId;
    final isPending = settlement.status == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Redirect Payment',
                      style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600, color: colors.foreground),
                    ),
                  ),
                  FBadge(
                    variant: _badgeVariant(settlement.status),
                    child: Text(settlement.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FTileGroup(
                children: [
                  FTile(
                    prefix: Icon(FIcons.user, size: 16,
                        color: colors.mutedForeground),
                    title: FutureBuilder<String>(
                      future: _resolveName(settlement.payerId),
                      builder: (_, s) => Text(
                        'Payer: ${s.data ?? "..."}',
                        style: typo.xs.copyWith(color: colors.foreground),
                      ),
                    ),
                  ),
                  FTile(
                    prefix: Icon(FIcons.userCheck, size: 16,
                        color: colors.mutedForeground),
                    title: FutureBuilder<String>(
                      future: _resolveName(settlement.receiverId),
                      builder: (_, s) => Text(
                        'Receiver: ${s.data ?? "..."}',
                        style: typo.xs.copyWith(color: colors.foreground),
                      ),
                    ),
                  ),
                  FTile(
                    prefix: Icon(FIcons.arrowRightLeft, size: 16,
                        color: colors.mutedForeground),
                    title: FutureBuilder<String>(
                      future: _resolveName(settlement.initiatorId),
                      builder: (_, s) => Text(
                        'Initiated by: ${s.data ?? "..."}',
                        style: typo.xs.copyWith(color: colors.foreground),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _fmt.format(settlement.amount),
                style: typo.lg.copyWith(
                    fontWeight: FontWeight.bold, color: colors.primary),
              ),
              if (isPayer && isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        variant: FButtonVariant.destructive,
                        onPress: () => _rejectSettlement(settlement.id),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FButton(
                        variant: FButtonVariant.primary,
                        onPress: () => _approveSettlement(settlement.id),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveSettlement(String id) async {
    try {
      await ref.read(settlementRepositoryProvider).approveSettlement(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settlement approved')));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settlement rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
