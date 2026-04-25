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
import '../transactions/transaction_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  String _fmtSigned(double amount) {
    final sign = amount >= 0 ? '+' : '−';
    return '$sign${_fmt.format(amount.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final name =
        ref
            .watch(currentUserProvider)
            .whenOrNull(data: (u) => u?.displayName) ??
        'there';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Header ─────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 60, 22, 14),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: colors.foreground,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: typo.lg.copyWith(
                          color: colors.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME BACK,',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.mutedForeground,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            style: typo.lg.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bell
                    GestureDetector(
                      onTap: () => _open(context, const NotificationScreen()),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: colors.foreground,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: colors.foreground,
                              size: 20,
                            ),
                            if (unread > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: colors.primary, // Accent
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Hero Slab ────────────────────────────────────────────────────
              _balanceHero(colors, typo),

              // ── Action Tiles ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Row(
                  children: [
                    _actionTile(
                      colors: colors,
                      icon: Icons.add,
                      label: 'New IOU',
                      sub: 'Split or charge',
                      fill: colors.primary, // Accent
                      onTap: () =>
                          _open(context, const CreateTransactionScreen()),
                    ),
                    const SizedBox(width: 10),
                    _actionTile(
                      colors: colors,
                      icon: Icons.send_outlined,
                      label: 'Request',
                      sub: 'Ask to pay',
                      fill: colors.card,
                      onTap: () => _open(
                        context,
                        const CreatePaymentRequestScreen(
                          mode: PaymentMode.requestPayment,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _actionTile(
                      colors: colors,
                      icon: Icons.qr_code_scanner,
                      label: 'Scan',
                      sub: 'QR receipt',
                      fill: colors.card,
                      onTap: () {}, // Not implemented
                    ),
                  ],
                ),
              ),

              // ── Recent Activity Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent activity',
                      style: typo.xl2.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'SEE ALL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                          letterSpacing: 0.8,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Transaction List ─────────────────────────────────────────────
              _transactionList(context, colors, typo),

              const SizedBox(height: 100), // Padding for CTA
            ],
          ),

          // ── Pinned CTA ─────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withValues(alpha: 0.0),
                    colors.background.withValues(alpha: 0.8),
                    colors.background,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: GestureDetector(
                onTap: () => _open(context, const CreateTransactionScreen()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    border: Border.all(color: colors.foreground, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colors.foreground,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: colors.foreground, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Start a new IOU',
                        style: typo.lg.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required FColors colors,
    required IconData icon,
    required String label,
    required String sub,
    required Color fill,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: colors.foreground, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: colors.foreground, size: 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.theme.typography.lg.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF3A352A), // Ink soft
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceHero(FColors colors, FTypography typo) {
    final async = ref.watch(balancesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.foreground, // Ink
          border: Border.all(color: colors.foreground, width: 1.5),
        ),
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (_, __) => Text(
            'Error loading balances',
            style: typo.sm.copyWith(color: colors.destructive),
          ),
          data: (balances) {
            final balanceRepo = ref.watch(balanceRepositoryProvider);
            final owe = balanceRepo.totalOwed(balances);
            final owed = balanceRepo.totalOwedToMe(balances);
            final net = owed - owe;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET BALANCE · APRIL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: const Color(0xFFA8A294),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _fmtSigned(net),
                  style: typo.xl4.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    color: colors.background, // Paper
                    height: 1.0,
                    letterSpacing: -0.88,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFF3A3528)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOU OWE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                color: const Color(0xFFA8A294),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt.format(owe),
                              style: typo.lg.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: colors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF3A3528),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFF3A3528)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OWED TO YOU',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                color: const Color(0xFFA8A294),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt.format(owed),
                              style: typo.lg.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: colors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _transactionList(
    BuildContext context,
    FColors colors,
    FTypography typo,
  ) {
    final async = ref.watch(transactionListProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: FCircularProgress()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $e',
          style: typo.sm.copyWith(color: colors.destructive),
        ),
      ),
      data: (txs) {
        final ids = txs.map((t) => t.creatorId).toSet().toList();
        ref.read(profileNameCacheProvider.notifier).prefetch(ids);
        final names = ref.watch(profileNameCacheProvider);

        if (txs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No recent activity',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              for (final tx in txs.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _txTile(context, tx, names, colors, typo),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _txTile(
    BuildContext context,
    Transaction tx,
    Map<String, String> names,
    FColors colors,
    FTypography typo,
  ) {
    final date = tx.createdAt != null
        ? DateFormat('MMM d').format(tx.createdAt!)
        : '';
    final creator = names[tx.creatorId] ?? '...';
    final isPending = tx.status == 'pending';

    // Calculate net amount for the current user for this transaction
    // In a real implementation this would use the transaction splits
    // For UI purposes, we use totalAmount but determine sign based on if we created it
    final currentUserId = ref.read(currentUserProvider).valueOrNull?.id;
    final isCreator = currentUserId != null && tx.creatorId == currentUserId;

    // If I created it, others owe me (+), otherwise I owe them (-)
    final amount = isCreator ? tx.totalAmount : -tx.totalAmount;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transactionId: tx.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.foreground, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description ?? 'Transaction',
                        style: typo.lg.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by $creator',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: colors.mutedForeground,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtSigned(amount),
                      style: typo.lg.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: amount >= 0
                            ? const Color(0xFF1F6A3A)
                            : colors.foreground, // Good or Ink
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: colors.mutedForeground,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isPending)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colors.foreground,
                      width: 1.0,
                      style: BorderStyle.none,
                    ),
                  ), // Dashed not natively supported easily without path, so use solid or custom painter
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AWAITING APPROVAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: colors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
