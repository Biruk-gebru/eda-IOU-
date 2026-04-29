import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/net_balance.dart';
import '../../providers/balance_providers.dart';
import '../../providers/payment_providers.dart';
import '../../providers/user_providers.dart';
import 'person_detail_screen.dart';

class PersonalScreen extends ConsumerStatefulWidget {
  const PersonalScreen({super.key});

  @override
  ConsumerState<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends ConsumerState<PersonalScreen> {
  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
  final _confirming = <String>{};

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final balancesAsync = ref.watch(balancesProvider);
    final balanceRepo = ref.watch(balanceRepositoryProvider);
    final userId = ref.watch(currentUserProvider).whenOrNull(data: (u) => u?.id);

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: SafeArea(
        child: balancesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
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
            final otherIds = balances
                .map((b) => userId == b.userA ? b.userB : b.userA)
                .toList();
            ref.read(profileNameCacheProvider.notifier).prefetch(otherIds);
            final names = ref.watch(profileNameCacheProvider);

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
              children: [
                Text(
                  'Personal',
                  style: typo.xl2.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your peer-to-peer balances',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Summary cards ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: colors.destructive,
                          border: Border.all(color: colors.foreground, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: colors.foreground, offset: const Offset(4, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colors.destructiveForeground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(FIcons.arrowUpRight, size: 14, color: colors.destructive),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'YOU OWE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: colors.destructiveForeground.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _fmt.format(owe),
                              style: typo.xl3.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colors.destructiveForeground,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          border: Border.all(color: colors.foreground, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: colors.foreground, offset: const Offset(4, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colors.primaryForeground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(FIcons.arrowDownLeft, size: 14, color: colors.primary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'OWED TO YOU',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: colors.primaryForeground.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _fmt.format(owed),
                              style: typo.xl3.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colors.primaryForeground,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Pending approvals ─────────────────────────────────────────────
                Consumer(
                  builder: (context, ref, _) {
                    final approvalsAsync = ref.watch(pendingApprovalsProvider);
                    final approvals = approvalsAsync.whenOrNull(data: (l) => l) ?? [];
                    if (approvals.isEmpty) return const SizedBox.shrink();

                    // Prefetch payer names
                    final payerIds = approvals.map((r) => r.payerId).toList();
                    ref.read(profileNameCacheProvider.notifier).prefetch(payerIds);
                    final names = ref.watch(profileNameCacheProvider);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PENDING APPROVALS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.card,
                            border: Border.all(color: colors.foreground, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: colors.foreground, offset: const Offset(3, 3)),
                            ],
                          ),
                          child: Column(
                            children: List.generate(approvals.length, (i) {
                              final req = approvals[i];
                              final payerName = names[req.payerId] ?? '...';
                              final initial = payerName.isNotEmpty
                                  ? payerName[0].toUpperCase()
                                  : '?';
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: i == 0
                                      ? null
                                      : Border(
                                          top: BorderSide(
                                              color: colors.foreground,
                                              width: 1.0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors.primary.withValues(alpha: 0.2),
                                        border: Border.all(
                                            color: colors.foreground, width: 1.5),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        initial,
                                        style: typo.lg.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: colors.foreground),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            payerName,
                                            style: typo.sm.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colors.foreground),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Paid ${_fmt.format(req.amount)}',
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: colors.mutedForeground),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _confirming.contains(req.id)
                                          ? null
                                          : () async {
                                              setState(() => _confirming.add(req.id));
                                              final messenger = ScaffoldMessenger.of(context);
                                              try {
                                                await ref
                                                    .read(paymentRepositoryProvider)
                                                    .confirmPayment(req.id);
                                                ref.invalidate(pendingApprovalsProvider);
                                                ref.invalidate(balancesProvider);
                                              } catch (e) {
                                                messenger.showSnackBar(
                                                  SnackBar(content: Text('Error: $e')),
                                                );
                                              } finally {
                                                if (mounted) setState(() => _confirming.remove(req.id));
                                              }
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          border: Border.all(
                                              color: colors.foreground, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                                color: colors.foreground,
                                                offset: const Offset(2, 2)),
                                          ],
                                        ),
                                        child: _confirming.contains(req.id)
                                            ? SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                    color: colors.foreground, strokeWidth: 2),
                                              )
                                            : Text(
                                                'Confirm',
                                                style: typo.xs.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.foreground,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),

                // ── Net balances ──────────────────────────────────────────────────
                Text(
                  'NET BALANCES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),

                if (balances.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('All settled up 🎉',
                          style: GoogleFonts.inter(fontSize: 14, color: colors.mutedForeground)),
                    ),
                  )
                else
                  Column(
                    children: List.generate(balances.length, (i) {
                      final b = balances[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _balanceTile(context, b, userId, names, colors, typo),
                      );
                    }),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _balanceTile(
      BuildContext context, NetBalance b, String? userId, Map<String, String> names, FColors colors, FTypography typo) {
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
    final label = owes ? 'You owe' : 'Owes you';
    final name = names[otherId] ?? '...';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          otherUserId: otherId,
          amount: amount,
          iOwe: owes,
        ),
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.foreground, width: 1.5),
          boxShadow: [
            BoxShadow(color: colors.foreground, offset: const Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: colors.foreground, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: typo.lg.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: typo.lg.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _fmt.format(amount),
              style: typo.lg.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
            const SizedBox(width: 12),
            Icon(FIcons.chevronRight, size: 18, color: colors.foreground),
          ],
        ),
      ),
    );
  }
}
