import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/net_balance.dart';
import '../../providers/balance_providers.dart';
import '../../providers/user_providers.dart';
import '../payments/create_payment_request_screen.dart';
import '../settlements/settlement_screen.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final balancesAsync = ref.watch(balancesProvider);
    final balanceRepo = ref.watch(balanceRepositoryProvider);
    final userId = ref.watch(currentUserProvider).whenOrNull(data: (u) => u?.id);

    return balancesAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FIcons.circleAlert, size: 40, color: colors.destructive),
            const SizedBox(height: 12),
            Text('Failed to load balances',
                style: typo.sm.copyWith(color: colors.mutedForeground)),
          ],
        ),
      ),
      data: (balances) {
        final owe = balanceRepo.totalOwed(balances);
        final owed = balanceRepo.totalOwedToMe(balances);

        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
          children: [
            Text('Personal',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                )),
            const SizedBox(height: 4),
            Text('Your peer-to-peer balances',
                style: typo.xs.copyWith(color: colors.mutedForeground)),
            const SizedBox(height: 20),

            // ── Summary card ─────────────────────────────────────────────────
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You owe',
                              style: typo.xs.copyWith(color: colors.mutedForeground)),
                          const SizedBox(height: 6),
                          Text(
                            _fmt.format(owe),
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colors.destructive,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: colors.border),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Owed to you',
                              style: typo.xs.copyWith(color: colors.mutedForeground)),
                          const SizedBox(height: 6),
                          Text(
                            _fmt.format(owed),
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Action buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreatePaymentRequestScreen()),
                    ),
                    prefix: const Icon(FIcons.handCoins),
                    child: const Text('Send payment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettlementScreen()),
                    ),
                    prefix: const Icon(FIcons.arrowRightLeft),
                    child: const Text('Redirect'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Net balances ──────────────────────────────────────────────────
            Text('Net balances',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                )),
            const SizedBox(height: 12),

            if (balances.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('All settled up 🎉',
                      style: typo.sm.copyWith(color: colors.mutedForeground)),
                ),
              )
            else
              FTileGroup(
                children: [
                  for (final b in balances) _balanceTile(b, userId, colors, typo),
                ],
              ),
          ],
        );
      },
    );
  }

  FTile _balanceTile(NetBalance b, String? userId, FColors colors, FTypography typo) {
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
    final color = owes ? colors.destructive : const Color(0xFF34D399);
    final label = owes ? 'You owe' : 'Owes you';
    final shortId = otherId.substring(0, otherId.length.clamp(0, 6));
    final initial = shortId.isNotEmpty ? shortId[0].toUpperCase() : '?';

    return FTile(
      prefix: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: Text(initial,
            style: typo.xs.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
      ),
      title: Text('User $shortId…',
          style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground)),
      subtitle: Text(label, style: typo.xs.copyWith(color: colors.mutedForeground)),
      details: Text(_fmt.format(amount),
          style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: color)),
    );
  }
}
