import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/transaction.dart';
import '../../providers/balance_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_providers.dart';
import '../payments/create_payment_request_screen.dart';
import '../transactions/create_transaction_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static final _fmt = NumberFormat.currency(symbol: 'ETB ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typo = theme.typography;

    final userAsync = ref.watch(currentUserProvider);
    final name =
        userAsync.whenOrNull(data: (u) => u?.displayName) ?? 'there';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Header
        Text(
          'Welcome back,',
          style: typo.sm.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: typo.lg.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 20),

        // Balance card
        _balanceCard(ref, colors, typo),

        const SizedBox(height: 16),

        // Quick actions — two rows to avoid overflow
        Row(
          children: [
            Expanded(
              child: FButton(
                onPress: () => _open(context, const CreateTransactionScreen()),
                prefix: const Icon(FIcons.plus),
                child: const Text('New'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () =>
                    _open(context, const CreatePaymentRequestScreen()),
                prefix: const Icon(FIcons.send),
                child: const Text('Request'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent transactions
        Text(
          'Recent transactions',
          style: typo.md.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        _transactionList(context, ref, colors, typo),
      ],
    );
  }

  Widget _balanceCard(WidgetRef ref, FColors colors, FTypography typo) {
    final async = ref.watch(balancesProvider);

    return async.when(
      loading: () => FCard.raw(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (_, __) => FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Could not load balances',
            style: typo.sm.copyWith(color: colors.destructive),
          ),
        ),
      ),
      data: (balances) {
        double owe = 0, owed = 0;
        for (final b in balances) {
          if (b.netAmount > 0) {
            owed += b.netAmount;
          } else {
            owe += b.netAmount.abs();
          }
        }

        return FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You owe',
                          style: typo.xs
                              .copyWith(color: colors.mutedForeground)),
                      const SizedBox(height: 4),
                      Text(
                        _fmt.format(owe),
                        style: typo.lg.copyWith(
                          color: colors.destructive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: colors.border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You are owed',
                          style: typo.xs
                              .copyWith(color: colors.mutedForeground)),
                      const SizedBox(height: 4),
                      Text(
                        _fmt.format(owed),
                        style: typo.lg.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _transactionList(
    BuildContext context,
    WidgetRef ref,
    FColors colors,
    FTypography typo,
  ) {
    final async = ref.watch(transactionListProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e',
            style: typo.sm.copyWith(color: colors.destructive)),
      ),
      data: (txs) {
        if (txs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No transactions yet',
                style: typo.sm.copyWith(color: colors.mutedForeground),
              ),
            ),
          );
        }

        return FTileGroup(
          children: [
            for (final tx in txs) _txTile(tx, colors, typo),
          ],
        );
      },
    );
  }

  FTile _txTile(Transaction tx, FColors colors, FTypography typo) {
    final date = tx.createdAt != null
        ? DateFormat('MMM d').format(tx.createdAt!)
        : '';

    return FTile(
      title: Text(tx.description ?? 'Transaction'),
      subtitle: Text(date),
      prefix: const Icon(FIcons.receipt),
      details: Text(
        _fmt.format(tx.totalAmount),
        style: typo.sm.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
      suffix: const Icon(FIcons.chevronRight),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
