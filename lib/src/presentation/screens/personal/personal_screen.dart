import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/net_balance.dart';
import '../../providers/balance_providers.dart';
import '../../providers/user_providers.dart';
import '../payments/create_payment_request_screen.dart';
import '../settlements/settlement_screen.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  static final _fmt = NumberFormat.currency(symbol: 'ETB ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typo = theme.typography;
    final balancesAsync = ref.watch(balancesProvider);
    final balanceRepo = ref.watch(balanceRepositoryProvider);
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.whenOrNull(data: (u) => u?.id);

    return balancesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FIcons.circleAlert, size: 40, color: colors.destructive),
            const SizedBox(height: 12),
            Text('Failed to load balances',
                style: typo.sm.copyWith(color: colors.destructive)),
          ],
        ),
      ),
      data: (balances) {
        final owe = balanceRepo.totalOwed(balances);
        final owed = balanceRepo.totalOwedToMe(balances);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Header
            Text('Personal',
                style: typo.lg.copyWith(
                    fontWeight: FontWeight.w600, color: colors.foreground)),
            const SizedBox(height: 16),

            // Summary card
            FCard.raw(
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
                          Text(_fmt.format(owe),
                              style: typo.lg.copyWith(
                                  color: colors.destructive,
                                  fontWeight: FontWeight.bold)),
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
                          Text(_fmt.format(owed),
                              style: typo.lg.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Net balances header
            Text('Net balances',
                style: typo.md.copyWith(
                    fontWeight: FontWeight.w600, color: colors.foreground)),
            const SizedBox(height: 12),

            if (balances.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No balances yet',
                      style: typo.sm
                          .copyWith(color: colors.mutedForeground)),
                ),
              )
            else
              FTileGroup(
                children: [
                  for (final b in balances)
                    _balanceTile(b, userId, colors, typo),
                ],
              ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const CreatePaymentRequestScreen())),
                    prefix: const Icon(FIcons.handCoins),
                    child: const Text('Pay'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettlementScreen())),
                    prefix: const Icon(FIcons.arrowRightLeft),
                    child: const Text('Redirect'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  FTile _balanceTile(
    NetBalance b,
    String? userId,
    FColors colors,
    FTypography typo,
  ) {
    final bool owes;
    final String otherId;
    if (userId == b.userA) {
      otherId = b.userB;
      owes = b.netAmount > 0;
    } else {
      otherId = b.userA;
      owes = b.netAmount < 0;
    }
    final amount = b.netAmount.abs();
    final color = owes ? colors.destructive : colors.primary;
    final label = owes ? 'You owe' : 'Owes you';

    return FTile(
      title: Text('User ${otherId.substring(0, otherId.length.clamp(0, 8))}'),
      subtitle: Text(label),
      details: Text(
        _fmt.format(amount),
        style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
