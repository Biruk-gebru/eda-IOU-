import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/payment_providers.dart';

class CreatePaymentRequestScreen extends ConsumerStatefulWidget {
  const CreatePaymentRequestScreen({super.key});

  @override
  ConsumerState<CreatePaymentRequestScreen> createState() => _CreatePaymentRequestScreenState();
}

class _CreatePaymentRequestScreenState extends ConsumerState<CreatePaymentRequestScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _receiverIdController = TextEditingController();
  String _selectedMethod = 'Bank transfer';
  bool _isSubmitting = false;

  static const _methods = ['Bank transfer', 'Mobile money', 'Cash'];

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
          const SnackBar(content: Text('Amount and receiver are required')));
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(paymentRepositoryProvider).createPaymentRequest(
            receiverId: receiverId,
            amount: amount,
            method: _selectedMethod,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment request sent')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Request Payment'),
        prefixes: [FHeaderAction.back(onPress: () => Navigator.of(context).pop())],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Receiver ──────────────────────────────────────────────────
            _label('RECEIVER', colors, typo),
            const SizedBox(height: 10),
            FTextField(
              control: FTextFieldControl.managed(controller: _receiverIdController),
              hint: 'User ID of the person who owes you',
              enabled: !_isSubmitting,
              prefixBuilder: (context, style, variants) =>
                  FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.user)),
            ),

            const SizedBox(height: 20),

            // ── Amount ───────────────────────────────────────────────────
            _label('AMOUNT (ETB)', colors, typo),
            const SizedBox(height: 10),
            FTextField(
              control: FTextFieldControl.managed(controller: _amountController),
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSubmitting,
              prefixBuilder: (context, style, variants) =>
                  FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.coins)),
            ),

            const SizedBox(height: 20),

            // ── Payment method ────────────────────────────────────────────
            _label('PAYMENT METHOD', colors, typo),
            const SizedBox(height: 10),
            Row(
              children: [
                for (int i = 0; i < _methods.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _methodChip(_methods[i], colors, typo),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // ── Note ──────────────────────────────────────────────────────
            _label('NOTE (OPTIONAL)', colors, typo),
            const SizedBox(height: 10),
            FTextField(
              control: FTextFieldControl.managed(controller: _noteController),
              hint: 'Add any extra instructions',
              minLines: 2,
              maxLines: 4,
              enabled: !_isSubmitting,
            ),

            const SizedBox(height: 28),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: _isSubmitting ? null : _submit,
                prefix: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: FCircularProgress())
                    : const Icon(FIcons.send),
                child: const Text('Send request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String method, FColors colors, FTypography typo) {
    final selected = _selectedMethod == method;
    return GestureDetector(
      onTap: _isSubmitting ? null : () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.card : colors.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.foreground.withValues(alpha: 0.3) : colors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          method,
          style: typo.xs.copyWith(
            color: selected ? colors.foreground : colors.mutedForeground,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _label(String text, FColors colors, FTypography typo) => Text(
        text,
        style: typo.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
          letterSpacing: 0.8,
        ),
      );
}
