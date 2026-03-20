import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/transaction.dart';
import '../../providers/balance_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_providers.dart';
import '../groups/groups_screen.dart';
import '../payments/create_payment_request_screen.dart';
import '../transactions/create_transaction_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static final _currencyFormat = NumberFormat.currency(symbol: 'ETB ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    final userAsync = ref.watch(currentUserProvider);
    final userName =
        userAsync.whenOrNull(data: (user) => user?.displayName) ?? 'there';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors, typography, userName),
              const SizedBox(height: 24),
              _buildBalanceCard(ref, colors, typography),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildSectionTitle(colors, typography, 'Recent Transactions'),
              const SizedBox(height: 16),
              _buildTransactionList(context, ref, colors, typography),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    FColors colors,
    FTypography typography,
    String userName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: typography.sm.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: typography.xl2.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    WidgetRef ref,
    FColors colors,
    FTypography typography,
  ) {
    final balancesAsync = ref.watch(balancesProvider);

    return balancesAsync.when(
      loading: () => FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: CircularProgressIndicator(color: colors.primary),
          ),
        ),
      ),
      error: (err, _) => FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading balances',
            style: typography.sm.copyWith(color: colors.destructive),
          ),
        ),
      ),
      data: (balances) {
        double totalOwed = 0;
        double totalOwing = 0;
        for (final b in balances) {
          if (b.netAmount > 0) {
            totalOwed += b.netAmount;
          } else {
            totalOwing += b.netAmount.abs();
          }
        }

        return FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance Overview',
                  style: typography.lg.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You owe',
                            style: typography.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(totalOwing),
                            style: typography.xl.copyWith(
                              color: colors.destructive,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: colors.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You are owed',
                              style: typography.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(totalOwed),
                              style: typography.xl.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FButton(
            variant: FButtonVariant.primary,
            onPress: () => _open(context, const CreateTransactionScreen()),
            prefix: Icon(FIcons.plus),
            child: const Text('New'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: () => _open(context, const CreatePaymentRequestScreen()),
            prefix: Icon(FIcons.send),
            child: const Text('Request'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FButton(
            variant: FButtonVariant.secondary,
            onPress: () => _open(context, const GroupsScreen()),
            prefix: Icon(FIcons.users),
            child: const Text('Groups'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    FColors colors,
    FTypography typography,
    String title,
  ) {
    return Text(
      title,
      style: typography.lg.copyWith(
        fontWeight: FontWeight.bold,
        color: colors.foreground,
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    FColors colors,
    FTypography typography,
  ) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return transactionsAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: colors.primary),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $err',
            style: typography.sm.copyWith(color: colors.destructive),
          ),
        ),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No transactions yet',
                style: typography.sm.copyWith(color: colors.mutedForeground),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final transaction in transactions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTransactionTile(
                  context,
                  transaction,
                  colors,
                  typography,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Transaction transaction,
    FColors colors,
    FTypography typography,
  ) {
    final dateStr = transaction.createdAt != null
        ? DateFormat('MMM d, y').format(transaction.createdAt!)
        : '-';

    return FTile(
      title: Text(transaction.description ?? 'Transaction'),
      subtitle: Text(dateStr),
      prefix: Icon(FIcons.receipt),
      details: Text(
        _currencyFormat.format(transaction.totalAmount),
        style: typography.sm.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
      suffix: Icon(FIcons.arrowRight),
      onPress: () {},
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
