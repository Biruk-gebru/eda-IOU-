import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/settlement_request.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settlement_providers.dart';
import '../../widgets/settlement_flow_animation.dart';

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

  Future<void> _openCreateSheet() async {
    final repo = ref.read(settlementRepositoryProvider);
    final contacts = await repo.getGroupContacts();
    if (!mounted) return;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least one shared group contact to create a settlement'),
        ),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateSettlementSheet(
        contacts: contacts,
        onSubmit: (payerId, receiverId, amount) async {
          try {
            await repo.createSettlementRequest(
              payerId: payerId,
              receiverId: receiverId,
              amount: amount,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settlement request created')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typo = theme.typography;
    final settlementsAsync = ref.watch(settlementRequestsProvider);
    final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSheet,
        backgroundColor: colors.primary,
        foregroundColor: colors.foreground,
        shape: const RoundedRectangleBorder(),
        child: const Icon(Icons.add),
      ),
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
                          const SizedBox(height: 16),
                          Text('No settlement requests yet',
                              style: GoogleFonts.inter(
                                  color: colors.mutedForeground)),
                          const SizedBox(height: 8),
                          Text('Tap + to create one',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colors.mutedForeground)),
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
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 100),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _sectionLabel('PENDING', colors),
                        const SizedBox(height: 12),
                        ...pending
                            .map((s) => _settlementTile(s, userId, colors, typo)),
                        const SizedBox(height: 32),
                      ],
                      if (approved.isNotEmpty) ...[
                        _sectionLabel('APPROVED', colors),
                        const SizedBox(height: 12),
                        ...approved
                            .map((s) => _settlementTile(s, userId, colors, typo)),
                        const SizedBox(height: 32),
                      ],
                      if (completed.isNotEmpty) ...[
                        _sectionLabel('COMPLETED / REJECTED', colors),
                        const SizedBox(height: 12),
                        ...completed
                            .map((s) => _settlementTile(s, userId, colors, typo)),
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

  Color _badgeColor(String status, FColors colors) => switch (status) {
        'approved' || 'completed' => colors.primary,
        'rejected' => colors.destructive,
        _ => colors.muted,
      };

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
          BoxShadow(color: colors.foreground, offset: const Offset(3, 3)),
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
                _buildInfoRow(FIcons.user, 'Payer',
                    _resolveName(settlement.payerId), colors, typo),
                const SizedBox(height: 8),
                _buildInfoRow(FIcons.userCheck, 'Receiver',
                    _resolveName(settlement.receiverId), colors, typo),
                const SizedBox(height: 8),
                _buildInfoRow(FIcons.arrowRightLeft, 'Initiated by',
                    _resolveName(settlement.initiatorId), colors, typo),
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
                        border: Border(
                            right: BorderSide(
                                color: colors.foreground, width: 1.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Reject',
                        style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _approveSettlement(settlement),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: colors.primary),
                      alignment: Alignment.center,
                      child: Text(
                        'Approve',
                        style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    Future<String> futureValue,
    FColors colors,
    FTypography typo,
  ) {
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
              s.data ?? '...',
              style: typo.sm
                  .copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveSettlement(SettlementRequest settlement) async {
    // Resolve names before showing the animation.
    final payerName = await _resolveName(settlement.payerId);
    final receiverName = await _resolveName(settlement.receiverId);
    final initiatorName = await _resolveName(settlement.initiatorId);

    if (!mounted) return;

    // Show the animated visualization while the approval runs in parallel.
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

// ── Create Settlement Sheet ────────────────────────────────────────────────────

class _CreateSettlementSheet extends StatefulWidget {
  const _CreateSettlementSheet({
    required this.contacts,
    required this.onSubmit,
  });

  final List<Map<String, dynamic>> contacts;
  final Future<void> Function(String payerId, String receiverId, double amount)
      onSubmit;

  @override
  State<_CreateSettlementSheet> createState() => _CreateSettlementSheetState();
}

class _CreateSettlementSheetState extends State<_CreateSettlementSheet> {
  String? _payerId;
  String? _receiverId;
  final _amountCtl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtl.text.trim());
    if (_payerId == null || _receiverId == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all fields')),
      );
      return;
    }
    if (_payerId == _receiverId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payer and receiver must be different people')),
      );
      return;
    }
    setState(() => _submitting = true);
    await widget.onSubmit(_payerId!, _receiverId!, amount);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Settlement',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Redirect a debt through a shared group contact.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _contactDropdown('PAYER (owes you)', _payerId, (v) => setState(() => _payerId = v), textColor),
          const SizedBox(height: 16),
          _contactDropdown('RECEIVER (you owe)', _receiverId, (v) => setState(() => _receiverId = v), textColor),
          const SizedBox(height: 16),
          _amountField(textColor),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _submitting ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: theme.colorScheme.primary,
              alignment: Alignment.center,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Create Settlement',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactDropdown(String label, String? value,
      ValueChanged<String?> onChanged, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: textColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: textColor, width: 1.5),
            ),
          ),
          hint: Text('Select person',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          items: widget.contacts.map((c) {
            final id = c['id'] as String;
            final name = c['display_name'] as String? ?? 'Unknown';
            return DropdownMenuItem(
              value: id,
              child: Text(name,
                  style: GoogleFonts.inter(fontSize: 14, color: textColor)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _amountField(Color textColor) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: textColor, width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AMOUNT',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(fontSize: 16, color: textColor),
          decoration: InputDecoration(
            prefixText: 'ETB  ',
            prefixStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}
