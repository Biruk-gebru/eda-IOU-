import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/balance_providers.dart';
import '../../providers/transaction_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final balancesAsync = ref.watch(balancesProvider);
    final txAsync = ref.watch(transactionListProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
      children: [
        Text('Statistics',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            )),
        const SizedBox(height: 4),
        Text('Financial overview', style: typo.xs.copyWith(color: colors.mutedForeground)),
        const SizedBox(height: 24),

        // Quick stats
        _quickStats(txAsync, balancesAsync, colors, typo),
        const SizedBox(height: 16),

        // Balance pie
        _balancePie(balancesAsync, colors, typo),
        const SizedBox(height: 16),

        // Monthly bars
        _monthlyBars(txAsync, colors, typo),
      ],
    );
  }

  Widget _quickStats(AsyncValue<dynamic> txAsync, AsyncValue<dynamic> balancesAsync,
      FColors colors, FTypography typo) {
    final txCount = txAsync.whenOrNull(data: (txs) => (txs as List).length) ?? 0;
    final balanceCount =
        balancesAsync.whenOrNull(data: (bs) => (bs as List).length) ?? 0;

    return Row(
      children: [
        _statCard(FIcons.receipt, '$txCount', 'Transactions', colors, typo),
        const SizedBox(width: 12),
        _statCard(FIcons.users, '$balanceCount', 'Active balances', colors, typo),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, FColors colors, FTypography typo) {
    return Expanded(
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: colors.mutedForeground),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  )),
              Text(label, style: typo.xs.copyWith(color: colors.mutedForeground)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balancePie(AsyncValue<dynamic> balancesAsync, FColors colors, FTypography typo) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance breakdown',
                style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
            const SizedBox(height: 16),
            balancesAsync.when(
              loading: () => const SizedBox(height: 160, child: Center(child: FCircularProgress())),
              error: (_, __) => SizedBox(
                  height: 160,
                  child: Center(child: Text('No data', style: typo.xs.copyWith(color: colors.mutedForeground)))),
              data: (balances) {
                double owe = 0, owed = 0;
                for (final b in balances) {
                  if (b.netAmount > 0) { owed += b.netAmount; } else { owe += b.netAmount.abs(); }
                }
                if (owe == 0 && owed == 0) {
                  return SizedBox(height: 160, child: Center(child: Text('All settled up ✓',
                      style: typo.sm.copyWith(color: colors.mutedForeground))));
                }
                return SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 36,
                          sections: [
                            PieChartSectionData(
                                value: owe,
                                color: colors.destructive,
                                radius: 24,
                                showTitle: false),
                            PieChartSectionData(
                                value: owed,
                                color: const Color(0xFF34D399),
                                radius: 24,
                                showTitle: false),
                          ],
                        )),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dot(colors.destructive, 'You owe', _fmt.format(owe), typo, colors),
                          const SizedBox(height: 12),
                          _dot(const Color(0xFF34D399), 'Owed to you', _fmt.format(owed), typo, colors),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c, String label, String amount, FTypography typo, FColors colors) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: typo.xs.copyWith(color: colors.mutedForeground)),
            Text(amount, style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
          ]),
        ],
      );

  Widget _monthlyBars(AsyncValue<dynamic> txAsync, FColors colors, FTypography typo) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly spending',
                style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
            const SizedBox(height: 16),
            txAsync.when(
              loading: () => const SizedBox(height: 180, child: Center(child: FCircularProgress())),
              error: (_, __) => SizedBox(
                height: 180,
                child: Center(child: Text('No data', style: typo.xs.copyWith(color: colors.mutedForeground))),
              ),
              data: (transactions) {
                final now = DateTime.now();
                final months = <String, double>{};
                for (var i = 5; i >= 0; i--) {
                  final m = DateTime(now.year, now.month - i);
                  months[DateFormat('MMM').format(m)] = 0;
                }
                for (final tx in transactions) {
                  if (tx.createdAt == null) continue;
                  final key = DateFormat('MMM').format(tx.createdAt!);
                  if (months.containsKey(key)) months[key] = months[key]! + tx.totalAmount;
                }
                final entries = months.entries.toList();
                final maxVal = entries.fold<double>(0, (p, e) => e.value > p ? e.value : p);
                if (maxVal == 0) {
                  return SizedBox(height: 180, child: Center(child: Text('No transactions yet',
                      style: typo.sm.copyWith(color: colors.mutedForeground))));
                }
                return SizedBox(
                  height: 180,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.25,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                          _fmt.format(rod.toY),
                          TextStyle(color: colors.primaryForeground, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(entries[idx].key,
                                  style: typo.xs.copyWith(color: colors.mutedForeground)),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (var i = 0; i < entries.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: entries[i].value,
                              color: colors.foreground.withValues(alpha: 0.25),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ],
                        ),
                    ],
                  )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
