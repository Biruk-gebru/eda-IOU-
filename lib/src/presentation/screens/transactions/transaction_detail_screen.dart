import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../../domain/entities/transaction.dart' as domain;
import '../../../domain/entities/transaction_participant.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionDetailProvider(transactionId));
    final participantsAsync =
        ref.watch(transactionParticipantsProvider(transactionId));
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Transaction Detail'),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: transactionAsync.when(
        data: (transaction) => _buildContent(
          context,
          ref,
          transaction,
          participantsAsync,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading transaction: $e'),
                const SizedBox(height: 16),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () =>
                      ref.invalidate(transactionDetailProvider(transactionId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    domain.Transaction transaction,
    AsyncValue<List<TransactionParticipant>> participantsAsync,
  ) {
    final currentUserId =
        ref.read(supabaseClientProvider).auth.currentUser?.id;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Transaction info card
        _buildInfoCard(context, transaction, dateFormat),
        const SizedBox(height: 20),

        // Payment details button (if current user is payer)
        if (currentUserId == transaction.payerId &&
            (transaction.status == 'approved' ||
                transaction.status == 'pending')) ...[
          FButton(
            onPress: () => _showPaymentInfo(context, ref),
            prefix: const Icon(Icons.payment),
            child: const Text('View Payment Details'),
          ),
          const SizedBox(height: 20),
        ],

        // Status timeline
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _buildTimeline(context, transaction, dateFormat),
        const SizedBox(height: 20),

        // Participants
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Participants',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        participantsAsync.when(
          data: (participants) => _buildParticipantsList(
            context,
            ref,
            participants,
            transaction,
            currentUserId,
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => FCard(
            title: const Text('Error'),
            subtitle: Text('Could not load participants: $e'),
          ),
        ),
        const SizedBox(height: 20),

        // Actions for the creator
        if (currentUserId == transaction.creatorId &&
            transaction.status == 'pending') ...[
          FButton(
            variant: FButtonVariant.outline,
            onPress: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Reminder sent to pending approvers')),
              );
            },
            prefix: const Icon(Icons.notifications_active_outlined),
            child: const Text('Remind Pending Approvers'),
          ),
          const SizedBox(height: 12),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timeout extended by 24h')),
              );
            },
            prefix: const Icon(Icons.schedule_outlined),
            child: const Text('Extend Timeout'),
          ),
        ],
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    domain.Transaction transaction,
    DateFormat dateFormat,
  ) {
    final statusLabel = _statusLabel(transaction.status);

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.description ?? 'No description',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FBadge(
                  variant: _badgeVariant(transaction.status),
                  child: Text(statusLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ETB ${transaction.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (transaction.createdAt != null)
              Text(
                'Created: ${dateFormat.format(transaction.createdAt!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            if (transaction.timeoutAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _timeoutText(transaction.timeoutAt!),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    domain.Transaction transaction,
    DateFormat dateFormat,
  ) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        title: 'Created',
        subtitle: transaction.createdAt != null
            ? dateFormat.format(transaction.createdAt!)
            : 'Unknown date',
        status: _StepStatus.done,
      ),
      _TimelineStep(
        title: 'Approvals',
        subtitle: transaction.status == 'approved'
            ? 'All participants approved'
            : transaction.status == 'rejected'
                ? 'Transaction was rejected'
                : 'Awaiting participant votes',
        status: transaction.status == 'approved'
            ? _StepStatus.done
            : transaction.status == 'rejected'
                ? _StepStatus.done
                : _StepStatus.inProgress,
      ),
      _TimelineStep(
        title: 'Net balance update',
        subtitle: transaction.status == 'approved'
            ? 'Balances updated'
            : 'Applies after majority approval',
        status: transaction.status == 'approved'
            ? _StepStatus.done
            : _StepStatus.pending,
      ),
    ];

    if (transaction.timeoutAt != null && transaction.status == 'pending') {
      steps.add(_TimelineStep(
        title: 'Auto-cancel',
        subtitle: 'Scheduled for ${dateFormat.format(transaction.timeoutAt!)}',
        status: _StepStatus.pending,
      ));
    }

    return Column(
      children: steps
          .map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTimelineCard(context, step),
              ))
          .toList(),
    );
  }

  Widget _buildTimelineCard(BuildContext context, _TimelineStep step) {
    Color iconColor;
    IconData icon;

    switch (step.status) {
      case _StepStatus.done:
        iconColor = const Color(0xFF00BFA5);
        icon = Icons.check_circle;
      case _StepStatus.inProgress:
        iconColor = const Color(0xFF6C63FF);
        icon = Icons.timelapse;
      case _StepStatus.pending:
        iconColor = Colors.grey;
        icon = Icons.radio_button_unchecked;
    }

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList(
    BuildContext context,
    WidgetRef ref,
    List<TransactionParticipant> participants,
    domain.Transaction transaction,
    String? currentUserId,
  ) {
    return Column(
      children: participants.map((participant) {
        final isCurrentUser = participant.userId == currentUserId;
        final isApproved = participant.approved == true;
        final isRejected = participant.approved == false;

        final badgeVariant = isApproved
            ? FBadgeVariant.primary
            : isRejected
                ? FBadgeVariant.destructive
                : FBadgeVariant.outline;
        final badgeText = isApproved
            ? 'Approved'
            : isRejected
                ? 'Rejected'
                : 'Pending';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FTile(
            title: Text(isCurrentUser ? 'You' : _shortId(participant.userId)),
            subtitle: Text('ETB ${participant.amountDue.toStringAsFixed(2)}'),
            prefix: CircleAvatar(
              radius: 18,
              backgroundColor: isApproved
                  ? const Color(0xFF00BFA5).withValues(alpha: 0.2)
                  : isRejected
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
              child: Text(
                isCurrentUser ? 'Y' : participant.userId[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isApproved
                      ? const Color(0xFF00BFA5)
                      : isRejected
                          ? Colors.red
                          : Colors.grey[700],
                ),
              ),
            ),
            suffix: FBadge(
              variant: badgeVariant,
              child: Text(badgeText),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showPaymentInfo(BuildContext context, WidgetRef ref) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await client
          .from('profiles')
          .select('bank_name, account_number, account_name')
          .eq('id', userId)
          .maybeSingle();

      if (context.mounted) {
        if (data == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No banking info found for payee.')),
          );
          return;
        }

        showModalBottomSheet(
          context: context,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Information',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                _paymentRow('Bank Name', data['bank_name'] ?? 'N/A'),
                const Divider(),
                _paymentRow('Account Name', data['account_name'] ?? 'N/A'),
                const Divider(),
                _paymentRow(
                    'Account Number', data['account_number'] ?? 'N/A'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching info: $e')),
        );
      }
    }
  }

  Widget _paymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          SelectableText(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  FBadgeVariant _badgeVariant(String status) {
    switch (status) {
      case 'approved':
        return FBadgeVariant.primary;
      case 'rejected':
      case 'cancelled':
        return FBadgeVariant.destructive;
      default:
        return FBadgeVariant.outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String _timeoutText(DateTime timeoutAt) {
    final remaining = timeoutAt.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Timeout expired';
    }
    final hours = remaining.inHours;
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    if (days > 0) {
      return 'Auto-cancels in ${days}d ${remainingHours}h';
    }
    return 'Auto-cancels in ${remainingHours}h';
  }

  String _shortId(String userId) {
    if (userId.length > 8) {
      return 'User ${userId.substring(0, 8)}';
    }
    return 'User $userId';
  }
}

enum _StepStatus { done, inProgress, pending }

class _TimelineStep {
  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final _StepStatus status;
}
