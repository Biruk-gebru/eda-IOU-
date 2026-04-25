import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(22),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.foreground, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors.foreground,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Confirm Payment',
              style: typo.lg.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.foreground, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.payerName,
                    style: typo.lg.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ETB ${widget.amount.toStringAsFixed(2)}',
                    style: typo.lg.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accept or reject within 48 hours.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _reject,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Reject',
                        style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _confirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        border: Border.all(color: colors.foreground, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: colors.foreground,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.foreground,
                              ),
                            )
                          : Text(
                              'Confirm',
                              style: typo.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                    ),
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
