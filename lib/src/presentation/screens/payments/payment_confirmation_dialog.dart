import 'package:flutter/material.dart';

class PaymentConfirmationDialog extends StatelessWidget {
  const PaymentConfirmationDialog({
    super.key,
    required this.payer,
    required this.receiver,
    required this.amount,
  });

  final String payer;
  final String receiver;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$payer marked ETB ${amount.toStringAsFixed(2)} as paid to $receiver.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.timer_outlined, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use the buttons below to accept or reject within 48 hours.',
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Reject'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
