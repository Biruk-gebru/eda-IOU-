import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/transaction.dart';
import '../../providers/balance_providers.dart';
import '../../providers/notification_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_providers.dart';
import '../notifications/notification_screen.dart';
import '../payments/create_payment_request_screen.dart';
import '../transactions/create_transaction_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final name = ref.watch(currentUserProvider).whenOrNull(data: (u) => u?.displayName) ?? 'there';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final unread = ref.watch(unreadCountProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              alignment: Alignment.center,
              child: Text(initial,
                  style: typo.sm.copyWith(
                      color: colors.foreground, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back',
                      style: typo.xs.copyWith(color: colors.mutedForeground)),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
            // Bell
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(FIcons.bell, color: colors.mutedForeground, size: 22),
                  onPressed: () => _open(context, const NotificationScreen()),
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.destructive,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Balance card ────────────────────────────────────────────────────
        _balanceCard(ref, colors, typo),

        const SizedBox(height: 16),

        // ── Quick actions ───────────────────────────────────────────────────
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
                onPress: () => _open(context, const CreatePaymentRequestScreen()),
                prefix: const Icon(FIcons.send),
                child: const Text('Request'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Recent transactions header ──────────────────────────────────────
        Row(
          children: [
            Text(
              'Recent transactions',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ],
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
          child: Center(child: FCircularProgress()),
        ),
      ),
      error: (_, __) => FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Could not load balances',
              style: typo.sm.copyWith(color: colors.destructive)),
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
        );
      },
    );
  }

  Widget _transactionList(BuildContext context, WidgetRef ref, FColors colors, FTypography typo) {
    final async = ref.watch(transactionListProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: FCircularProgress()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e', style: typo.sm.copyWith(color: colors.destructive)),
      ),
      data: (txs) {
        if (txs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FIcons.receipt, size: 40, color: colors.border),
                  const SizedBox(height: 12),
                  Text('No transactions yet',
                      style: typo.sm.copyWith(color: colors.mutedForeground)),
                ],
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
    final date = tx.createdAt != null ? DateFormat('MMM d').format(tx.createdAt!) : '';
    return FTile(
      title: Text(tx.description ?? 'Transaction',
          style: typo.sm.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(date, style: typo.xs.copyWith(color: colors.mutedForeground)),
      prefix: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(FIcons.receipt, size: 16, color: colors.mutedForeground),
      ),
      details: Text(
        _fmt.format(tx.totalAmount),
        style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground),
      ),
      suffix: Icon(FIcons.chevronRight, size: 14, color: colors.border),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
