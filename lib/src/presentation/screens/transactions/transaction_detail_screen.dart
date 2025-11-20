import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        title: 'Created by You',
        subtitle: 'Weekend Trip • Nov 15, 10:32 AM',
        status: StepStatus.done,
      ),
      _TimelineStep(
        title: 'Approvals',
        subtitle: '2 of 4 approved • awaiting Liya & Tomas',
        status: StepStatus.inProgress,
      ),
      _TimelineStep(
        title: 'Net balance update',
        subtitle: 'Applies after majority approval',
        status: StepStatus.pending,
      ),
      _TimelineStep(
        title: 'Auto-cancel',
        subtitle: 'Scheduled for Nov 17, 10:32 AM',
        status: StepStatus.pending,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction detail'),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 24),
          Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineTile(step: step),
            ),
          ),
          const SizedBox(height: 24),
          Text('Participants', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _ParticipantTile(name: 'You', amount: 340, status: 'Approved'),
          _ParticipantTile(name: 'Liya', amount: 340, status: 'Pending'),
          _ParticipantTile(name: 'Tomas', amount: 340, status: 'Pending'),
          _ParticipantTile(name: 'Sarah', amount: 340, status: 'Approved'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Remind pending approvers'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.schedule_outlined),
            label: const Text('Extend timeout'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Weekend Trip • Airbnb',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Chip(label: Text('Pending approval')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ETB 1,360.00',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Auto-cancels in 1d 6h if not fully approved.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

enum StepStatus { done, inProgress, pending }

class _TimelineStep {
  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final StepStatus status;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.step});

  final _TimelineStep step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color borderColor;
    IconData icon;

    switch (step.status) {
      case StepStatus.done:
        borderColor = Colors.teal;
        icon = Icons.check_circle;
        break;
      case StepStatus.inProgress:
        borderColor = colorScheme.secondary;
        icon = Icons.timelapse;
        break;
      case StepStatus.pending:
        borderColor = Colors.grey[300]!;
        icon = Icons.radio_button_unchecked;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(step.subtitle, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.name,
    required this.amount,
    required this.status,
  });

  final String name;
  final double amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isApproved = status == 'Approved';

    return ListTile(
      leading: CircleAvatar(child: Text(name.characters.first)),
      title: Text(name),
      subtitle: Text(status),
      trailing: Text(
        'ETB ${amount.toStringAsFixed(0)}',
        style: TextStyle(
          color: isApproved ? Colors.teal : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
