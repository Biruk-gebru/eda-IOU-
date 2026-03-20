import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/net_balance.dart';
import '../../providers/balance_providers.dart';
import '../../providers/user_providers.dart';
import '../payments/create_payment_request_screen.dart';

final _currencyFormat = NumberFormat.currency(symbol: 'ETB ');

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(balancesProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final balanceRepo = ref.watch(balanceRepositoryProvider);

    return balancesAsync.when(
      loading: () => const Center(child: FProgress()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load balances',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (balances) {
        final totalOwed = balanceRepo.totalOwed(balances);
        final totalOwedToMe = balanceRepo.totalOwedToMe(balances);

        final currentUserId = currentUserAsync.whenOrNull(
          data: (user) => user?.id,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(context, totalOwed, totalOwedToMe),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Net balances',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (balances.isEmpty)
              FCard(
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No balances yet. Start splitting expenses!'),
                  ),
                ),
              )
            else
              ...balances.map(
                (balance) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildBalanceTile(context, balance, currentUserId),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openRequestPayment(context),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Settle up'),
            ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalOwed,
    double totalOwedToMe,
  ) {
    return FCard(
      title: const Text('Balance Summary'),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('You owe'),
                      const SizedBox(width: 8),
                      FBadge(
                        variant: FBadgeVariant.destructive,
                        child: Text(_currencyFormat.format(totalOwed)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('You are owed'),
                      const SizedBox(width: 8),
                      FBadge(
                        variant: FBadgeVariant.primary,
                        child: Text(_currencyFormat.format(totalOwedToMe)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceTile(
    BuildContext context,
    NetBalance balance,
    String? currentUserId,
  ) {
    // Determine if the current user owes or is owed.
    // If user is userA and netAmount > 0, userA owes userB.
    // If user is userB and netAmount < 0, userB owes userA.
    final bool currentUserOwes;
    final String otherUserId;
    final double displayAmount;

    if (currentUserId == balance.userA) {
      otherUserId = balance.userB;
      currentUserOwes = balance.netAmount > 0;
      displayAmount = balance.netAmount.abs();
    } else {
      otherUserId = balance.userA;
      currentUserOwes = balance.netAmount < 0;
      displayAmount = balance.netAmount.abs();
    }

    final color = currentUserOwes ? Colors.red.shade700 : Colors.green.shade700;
    final label = currentUserOwes ? 'You owe' : 'Owes you';

    return FTile(
      title: Text(
        'User ${otherUserId.substring(0, otherUserId.length.clamp(0, 8))}',
      ),
      subtitle: Text(label),
      prefix: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          currentUserOwes ? Icons.call_made : Icons.call_received,
          color: color,
          size: 20,
        ),
      ),
      details: Text(
        _currencyFormat.format(displayAmount),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openRequestPayment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePaymentRequestScreen()),
    );
  }
}
