import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../providers/balance_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_providers.dart';
import '../../../domain/entities/transaction.dart' as domain;
import '../../../domain/entities/transaction_participant.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _voting = false;
  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  Future<void> _vote(bool approve) async {
    setState(() => _voting = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final result = await repo.voteTransaction(widget.transactionId, approve);
      final status = result['status'] as String? ?? 'pending';

      ref.invalidate(transactionDetailProvider(widget.transactionId));
      ref.invalidate(transactionParticipantsProvider(widget.transactionId));
      ref.invalidate(transactionListProvider);
      ref.invalidate(balancesProvider);

      if (mounted) {
        final msg = approve
            ? (status == 'approved'
                  ? 'Transaction approved — balances updated'
                  : 'Vote recorded')
            : (status == 'rejected' ? 'Transaction rejected' : 'Vote recorded');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final txAsync = ref.watch(transactionDetailProvider(widget.transactionId));
    final partsAsync = ref.watch(
      transactionParticipantsProvider(widget.transactionId),
    );
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;

    final isCreator =
        txAsync.whenOrNull(data: (tx) => tx.creatorId == currentUserId) ??
        false;

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: SafeArea(
        bottom: false,
        child: txAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FIcons.circleAlert, size: 40, color: colors.destructive),
                const SizedBox(height: 12),
                Text(
                  'Error: $e',
                  style: typo.sm.copyWith(color: colors.destructive),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => ref.invalidate(
                    transactionDetailProvider(widget.transactionId),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.foreground, width: 1.5),
                    ),
                    child: Text(
                      'Retry',
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
          data: (tx) {
            return Stack(
              children: [
                Column(
                  children: [
                    // ── Header ──────────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colors.foreground,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colors.foreground,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '←',
                                style: typo.lg.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Transaction',
                              style: typo.lg.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                          ),
                          if (isCreator)
                            GestureDetector(
                              onTap: () => _confirmDelete(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colors.foreground,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Scrollable Body ───────────────────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 120),
                        children: [
                          // ── Hero Info ───────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statusLabel(tx.status).toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tx.description ?? 'No description',
                                  style: typo.xl2.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: colors.foreground,
                                    height: 1.1,
                                    letterSpacing: -0.28,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _fmt.format(tx.totalAmount),
                                  style: typo.xl4.copyWith(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w600,
                                    color: colors.foreground,
                                    letterSpacing: -0.88,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                partsAsync.when(
                                  data: (parts) => Text(
                                    '${isCreator ? 'paid by you' : 'paid by someone else'} · split ${parts.length} ways',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: colors.mutedForeground,
                                    ),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                                if (tx.timeoutAt != null &&
                                    tx.status == 'pending') ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeoutText(tx.timeoutAt!),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: colors.destructive,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // ── Participants Box ────────────────────────────────
                          partsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(22),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.all(22),
                              child: Text('Error: $e'),
                            ),
                            data: (parts) {
                              final ids = parts.map((p) => p.userId).toList();
                              ref
                                  .read(profileNameCacheProvider.notifier)
                                  .prefetch(ids);
                              final names = ref.watch(profileNameCacheProvider);
                              return _participantsBox(
                                parts,
                                tx,
                                currentUserId,
                                names,
                                colors,
                                typo,
                              );
                            },
                          ),

                          // ── Timeline ────────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                            child: Text(
                              'Timeline',
                              style: typo.lg.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: _timelineList(tx, colors, typo),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Fixed Bottom Actions ────────────────────────────────────
                partsAsync.when(
                  data: (parts) {
                    final myEntry = parts
                        .where(
                          (p) =>
                              p.userId == currentUserId && p.approved == null,
                        )
                        .firstOrNull;
                    final canVote = myEntry != null && tx.status == 'pending';

                    if (!canVote) return const SizedBox.shrink();

                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                        decoration: BoxDecoration(
                          color: colors.background, // Paper
                          border: Border(
                            top: BorderSide(
                              color: colors.foreground,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _voting ? null : () => _vote(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: colors.foreground,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Decline',
                                    style: typo.lg.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.foreground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: _voting ? null : () => _vote(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary, // Accent
                                    border: Border.all(
                                      color: colors.foreground,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.foreground,
                                        offset: const Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: _voting
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: colors.foreground,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Approve',
                                          style: typo.lg.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.foreground,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _participantsBox(
    List<TransactionParticipant> parts,
    domain.Transaction tx,
    String? currentUserId,
    Map<String, String> names,
    FColors colors,
    FTypography typo,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.foreground, width: 1.5),
      ),
      child: Column(
        children: List.generate(parts.length, (i) {
          final p = parts[i];
          final name = names[p.userId] ?? '...';
          final isMe = p.userId == currentUserId;

          String statusText = 'Pending';
          if (p.approved == true) statusText = 'Approved';
          if (p.approved == false) statusText = 'Rejected';
          if (tx.creatorId == p.userId) statusText = 'Paid';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : Border(
                      top: BorderSide(color: colors.foreground, width: 1.0),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: colors.foreground, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: typo.lg.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? 'You' : name,
                        style: typo.lg.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _fmt.format(p.amountDue),
                  style: typo.lg.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _timelineList(
    domain.Transaction tx,
    FColors colors,
    FTypography typo,
  ) {
    final steps = [
      ('Created', true),
      ('Approvals', tx.status == 'approved' || tx.status == 'rejected'),
      ('Balances updated', tx.status == 'applied'),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final (label, done) = steps[i];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: i == 0
                ? Border(top: BorderSide(color: colors.foreground, width: 1.5))
                : const Border(top: BorderSide(color: Colors.transparent)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: done ? colors.foreground : Colors.transparent,
                  border: Border.all(color: colors.foreground, width: 1.2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i == 0
                          ? 'NOW'
                          : 'PENDING', // Ideally these are real timestamps
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: colors.mutedForeground,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _statusLabel(String s) => switch (s) {
    'approved' => 'Approved',
    'applied' => 'Applied',
    'rejected' => 'Rejected',
    'cancelled' => 'Cancelled',
    'pending' => 'Pending Approval',
    _ => s,
  };

  String _timeoutText(DateTime t) {
    final r = t.difference(DateTime.now());
    if (r.isNegative) return 'Timeout expired';
    final h = r.inHours;
    return h >= 24
        ? 'Auto-cancels in ${h ~/ 24}d ${h % 24}h'
        : 'Auto-cancels in ${h}h';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final tx = ref
        .read(transactionDetailProvider(widget.transactionId))
        .valueOrNull;
    final isPending = tx?.status == 'pending';
    
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
                'Delete transaction',
                style: typo.lg.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isPending
                    ? 'This will cancel and delete this pending transaction.'
                    : 'This approved transaction will be reversed. All participants will be notified.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.mutedForeground,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        try {
                          final repo = ref.read(transactionRepositoryProvider);
                          if (isPending) {
                            await ref
                                .read(supabaseClientProvider)
                                .from('transactions')
                                .update({'status': 'cancelled'})
                                .eq('id', widget.transactionId);
                          }
                          await repo.deleteTransaction(widget.transactionId);

                          ref.invalidate(transactionListProvider);
                          ref.invalidate(balancesProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transaction deleted')),
                            );
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                          'Delete',
                          style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
