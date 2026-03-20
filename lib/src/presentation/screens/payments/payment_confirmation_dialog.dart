import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/payment_providers.dart';

class PaymentConfirmationDialog extends ConsumerStatefulWidget {
  const PaymentConfirmationDialog({
    super.key,
    required this.paymentRequestId,
    required this.amount,
    required this.payerName,
  });

  final String paymentRequestId;
  final double amount;
  final String payerName;

  @override
  ConsumerState<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState
    extends ConsumerState<PaymentConfirmationDialog> {
  bool _isLoading = false;

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.confirmPayment(widget.paymentRequestId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.rejectPayment(widget.paymentRequestId);
      if (mounted) Navigator.of(context).pop(false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Confirm Payment',
              style: context.theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            FCard(
              title: Text(widget.payerName),
              subtitle: Text(
                'ETB ${widget.amount.toStringAsFixed(2)}',
              ),
              child: const Text(
                'Accept or reject within 48 hours.',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: _isLoading ? null : _reject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    onPress: _isLoading ? null : _confirm,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
