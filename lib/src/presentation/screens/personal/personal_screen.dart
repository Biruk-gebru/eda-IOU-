import 'package:flutter/material.dart';

class PersonalScreen extends StatelessWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final balances = [
      _BalanceSummary(name: 'Liya', amount: -180),
      _BalanceSummary(name: 'Tomas', amount: 220),
      _BalanceSummary(name: 'Family', amount: -40),
      _BalanceSummary(name: 'Solo expenses', amount: 0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'Netting history',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildBalanceHeader(context),
          const SizedBox(height: 24),
          Text('Net balances', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...balances.map(
            (balance) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BalanceCard(summary: balance),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Settle up'),
          ),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.request_page_outlined),
        label: const Text('Request payment'),
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer,
            colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Overall balance', style: TextStyle(color: Colors.black54)),
          SizedBox(height: 4),
          Text(
            'ETB 1,280.00',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Positive amount means people owe you.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _BalanceSummary {
  _BalanceSummary({required this.name, required this.amount});

  final String name;
  final double amount;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final _BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.amount >= 0;
    final color = isPositive ? Colors.teal : Colors.deepOrange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              isPositive ? Icons.call_received : Icons.call_made,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isPositive ? 'Owes you' : 'You owe',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            'ETB ${summary.amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
