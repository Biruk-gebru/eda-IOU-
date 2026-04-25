import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
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
                      'Settlements',
                      style: typo.xl2.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: settlementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FIcons.circleAlert, size: 40, color: colors.destructive),
                      const SizedBox(height: 16),
                      Text('Failed to load settlements', style: typo.sm.copyWith(color: colors.destructive)),
                    ],
                  ),
                ),
                data: (settlements) {
                  if (settlements.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FIcons.arrowRightLeft, size: 48, color: colors.mutedForeground),
                          const SizedBox(height: 16),
                          Text('No settlement requests yet', style: GoogleFonts.inter(color: colors.mutedForeground)),
                        ],
                      ),
                    );
                  }

                  final pending = settlements.where((s) => s.status == 'pending').toList();
                  final approved = settlements.where((s) => s.status == 'approved').toList();
                  final completed = settlements.where((s) => s.status == 'completed' || s.status == 'rejected').toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _sectionLabel('PENDING', colors),
                        const SizedBox(height: 12),
                        ...pending.map((s) => _settlementTile(s, userId, colors, typo)),
                        const SizedBox(height: 32),
                      ],
                      if (approved.isNotEmpty) ...[
                        _sectionLabel('APPROVED', colors),
                        const SizedBox(height: 12),
                        ...approved.map((s) => _settlementTile(s, userId, colors, typo)),
                        const SizedBox(height: 32),
                      ],
                      if (completed.isNotEmpty) ...[
                        _sectionLabel('COMPLETED / REJECTED', colors),
                        const SizedBox(height: 12),
                        ...completed.map((s) => _settlementTile(s, userId, colors, typo)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, FColors colors) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: colors.mutedForeground,
      ),
    );
  }

  Color _badgeColor(String status, FColors colors) {
    switch (status) {
      case 'approved':
      case 'completed':
        return colors.primary; // Or a success color
      case 'rejected':
        return colors.destructive;
      default:
        return colors.muted;
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
    final badgeColor = _badgeColor(settlement.status, colors);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Redirect Payment',
                    style: typo.lg.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    border: Border.all(color: colors.foreground, width: 1.5),
                  ),
                  child: Text(
                    settlement.status.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1.5, color: colors.foreground),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(FIcons.user, 'Payer', _resolveName(settlement.payerId), colors, typo),
                const SizedBox(height: 8),
                _buildInfoRow(FIcons.userCheck, 'Receiver', _resolveName(settlement.receiverId), colors, typo),
                const SizedBox(height: 8),
                _buildInfoRow(FIcons.arrowRightLeft, 'Initiated by', _resolveName(settlement.initiatorId), colors, typo),
              ],
            ),
          ),
          Container(height: 1.5, color: colors.foreground),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _fmt.format(settlement.amount),
              style: typo.xl3.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
                letterSpacing: -0.56,
              ),
            ),
          ),
          if (isPayer && isPending) ...[
            Container(height: 1.5, color: colors.foreground),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _rejectSettlement(settlement.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: colors.destructive,
                        border: Border(right: BorderSide(color: colors.foreground, width: 1.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Reject',
                        style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _approveSettlement(settlement.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: colors.primary,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Approve',
                        style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Future<String> futureValue, FColors colors, FTypography typo) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.foreground),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.inter(fontSize: 13, color: colors.mutedForeground),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FutureBuilder<String>(
            future: futureValue,
            builder: (_, s) => Text(
              s.data ?? "...",
              style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
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
