import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../providers/transaction_providers.dart';
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
  final Map<String, String> _nameCache = {};
  bool _voting = false;

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

  Future<void> _vote(bool approve) async {
    setState(() => _voting = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final result =
          await repo.voteTransaction(widget.transactionId, approve);
      final status = result['status'] as String? ?? 'pending';

      ref.invalidate(transactionDetailProvider(widget.transactionId));
      ref.invalidate(
          transactionParticipantsProvider(widget.transactionId));
      ref.invalidate(transactionListProvider);

      if (mounted) {
        final msg = approve
            ? (status == 'approved'
                ? 'Transaction approved — balances updated'
                : 'Vote recorded')
            : (status == 'rejected'
                ? 'Transaction rejected'
                : 'Vote recorded');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final partsAsync =
        ref.watch(transactionParticipantsProvider(widget.transactionId));
    final currentUserId =
        ref.read(supabaseClientProvider).auth.currentUser?.id;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Transaction'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FIcons.circleAlert, size: 40, color: colors.destructive),
              const SizedBox(height: 12),
              Text('Error: $e',
                  style: typo.sm.copyWith(color: colors.destructive)),
              const SizedBox(height: 16),
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => ref
                    .invalidate(transactionDetailProvider(widget.transactionId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tx) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
          children: [
            // Info card
            _infoCard(tx, colors, typo),
            const SizedBox(height: 20),

            // Timeline
            _label('STATUS', colors, typo),
            const SizedBox(height: 10),
            _timeline(tx, colors, typo),
            const SizedBox(height: 24),

            // Participants + voting
            _label('PARTICIPANTS', colors, typo),
            const SizedBox(height: 10),
            partsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (parts) => _participantsList(
                  parts, tx, currentUserId, colors, typo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
      domain.Transaction tx, FColors colors, FTypography typo) {
    final fmt = DateFormat('MMM d, yyyy h:mm a');

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tx.description ?? 'No description',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground)),
                ),
                FBadge(
                  variant: _badgeVariant(tx.status),
                  child: Text(_statusLabel(tx.status)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('ETB ${tx.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground)),
            const SizedBox(height: 8),
            if (tx.createdAt != null)
              Text('Created ${fmt.format(tx.createdAt!)}',
                  style: typo.xs.copyWith(color: colors.mutedForeground)),
            if (tx.timeoutAt != null && tx.status == 'pending') ...[
              const SizedBox(height: 4),
              Text(_timeoutText(tx.timeoutAt!),
                  style: typo.xs.copyWith(color: colors.mutedForeground)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeline(
      domain.Transaction tx, FColors colors, FTypography typo) {
    final steps = [
      ('Created', true),
      ('Approvals',
          tx.status == 'approved' || tx.status == 'rejected'),
      ('Balances updated', tx.status == 'applied'),
    ];

    return Column(
      children: [
        for (final (label, done) in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FTile(
              prefix: Icon(
                done ? FIcons.circleCheck : FIcons.circle,
                size: 18,
                color: done ? colors.primary : colors.mutedForeground,
              ),
              title: Text(label,
                  style: typo.sm.copyWith(
                      color: done ? colors.foreground : colors.mutedForeground,
                      fontWeight: done ? FontWeight.w500 : FontWeight.normal)),
            ),
          ),
      ],
    );
  }

  Widget _participantsList(
    List<TransactionParticipant> parts,
    domain.Transaction tx,
    String? currentUserId,
    FColors colors,
    FTypography typo,
  ) {
    // Check if current user is a pending participant
    final myEntry = parts
        .where((p) => p.userId == currentUserId && p.approved == null)
        .firstOrNull;
    final canVote = myEntry != null && tx.status == 'pending';

    return Column(
      children: [
        for (final p in parts)
          FutureBuilder<String>(
            future: _resolveName(p.userId),
            builder: (context, snap) {
              final name = snap.data ?? '...';
              final isMe = p.userId == currentUserId;
              final statusText = p.approved == true
                  ? 'Approved'
                  : p.approved == false
                      ? 'Rejected'
                      : 'Pending';
              final statusColor = p.approved == true
                  ? colors.primary
                  : p.approved == false
                      ? colors.destructive
                      : colors.mutedForeground;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: FCard.raw(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: typo.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isMe ? 'You' : name,
                                  style: typo.sm.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colors.foreground)),
                              Text(
                                  'ETB ${p.amountDue.toStringAsFixed(2)} · $statusText',
                                  style: typo.xs
                                      .copyWith(color: colors.mutedForeground)),
                            ],
                          ),
                        ),
                        FBadge(
                          variant: p.approved == true
                              ? FBadgeVariant.primary
                              : p.approved == false
                                  ? FBadgeVariant.destructive
                                  : FBadgeVariant.outline,
                          child: Text(statusText),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // Approve / Reject buttons for current user
        if (canVote) ...[
          const SizedBox(height: 16),
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your approval is needed',
                      style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground)),
                  const SizedBox(height: 4),
                  Text(
                      'You owe ETB ${myEntry.amountDue.toStringAsFixed(2)} to the payer',
                      style:
                          typo.xs.copyWith(color: colors.mutedForeground)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          variant: FButtonVariant.destructive,
                          onPress: _voting ? null : () => _vote(false),
                          prefix: const Icon(FIcons.x),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FButton(
                          onPress: _voting ? null : () => _vote(true),
                          prefix: _voting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator
                                      .adaptive(strokeWidth: 2))
                              : const Icon(FIcons.check),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text, FColors colors, FTypography typo) => Text(
        text,
        style: typo.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
          letterSpacing: 0.8,
        ),
      );

  FBadgeVariant _badgeVariant(String status) => switch (status) {
        'approved' || 'applied' => FBadgeVariant.primary,
        'rejected' || 'cancelled' => FBadgeVariant.destructive,
        _ => FBadgeVariant.outline,
      };

  String _statusLabel(String s) => switch (s) {
        'approved' => 'Approved',
        'applied' => 'Applied',
        'rejected' => 'Rejected',
        'cancelled' => 'Cancelled',
        'pending' => 'Pending',
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
}
