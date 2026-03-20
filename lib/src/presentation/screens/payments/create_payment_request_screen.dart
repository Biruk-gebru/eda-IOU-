import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/payment_providers.dart';

class CreatePaymentRequestScreen extends ConsumerStatefulWidget {
  const CreatePaymentRequestScreen({super.key});

  @override
  ConsumerState<CreatePaymentRequestScreen> createState() =>
      _CreatePaymentRequestScreenState();
}

class _CreatePaymentRequestScreenState
    extends ConsumerState<CreatePaymentRequestScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _receiverIdController = TextEditingController();
  String _selectedMethod = 'Bank transfer';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _receiverIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final receiverId = _receiverIdController.text.trim();

    if (amountText.isEmpty || receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount and receiver are required')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.createPaymentRequest(
        receiverId: receiverId,
        amount: amount,
        method: _selectedMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment request sent')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Request Payment'),
        prefixes: [
          FHeaderAction(
            icon: const Icon(FIcons.chevronLeft),
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FTextField(
              control: FTextFieldControl.managed(
                controller: _receiverIdController,
              ),
              label: const Text('Receiver ID'),
              hint: 'Enter the receiver user ID',
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            FTextField(
              control: FTextFieldControl.managed(
                controller: _amountController,
              ),
              label: const Text('Amount (ETB)'),
              hint: 'e.g. 500.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            Text(
              'Preferred Method',
              style: context.theme.typography.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: context.theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _methodChip('Bank transfer'),
                const SizedBox(width: 8),
                _methodChip('Mobile money'),
                const SizedBox(width: 8),
                _methodChip('Cash'),
              ],
            ),
            const SizedBox(height: 16),
            FTextField(
              control: FTextFieldControl.managed(
                controller: _noteController,
              ),
              label: const Text('Note (optional)'),
              hint: 'Add any extra instructions',
              minLines: 2,
              maxLines: 4,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 24),
            FButton(
              onPress: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String method) {
    final selected = _selectedMethod == method;
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? context.theme.colors.primary
              : context.theme.colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? context.theme.colors.primary
                : context.theme.colors.border,
          ),
        ),
        child: Text(
          method,
          style: TextStyle(
            color: selected
                ? context.theme.colors.primaryForeground
                : context.theme.colors.foreground,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
