import 'package:flutter/material.dart';

class CreatePaymentRequestScreen extends StatefulWidget {
  const CreatePaymentRequestScreen({super.key});

  @override
  State<CreatePaymentRequestScreen> createState() =>
      _CreatePaymentRequestScreenState();
}

class _CreatePaymentRequestScreenState
    extends State<CreatePaymentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedPayer = 'Liya';
  String _selectedMethod = 'Bank transfer';
  bool _linkTransaction = true;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request payment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPayer,
                  decoration: const InputDecoration(labelText: 'Payer'),
                  items: const [
                    DropdownMenuItem(value: 'Liya', child: Text('Liya')),
                    DropdownMenuItem(value: 'Tomas', child: Text('Tomas')),
                    DropdownMenuItem(value: 'Sarah', child: Text('Sarah')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPayer = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (ETB)',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Preferred method',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bank transfer',
                      child: Text('Bank transfer'),
                    ),
                    DropdownMenuItem(
                      value: 'Mobile money',
                      child: Text('Mobile money'),
                    ),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _linkTransaction,
                  onChanged: (value) =>
                      setState(() => _linkTransaction = value),
                  title: const Text('Link to transaction'),
                  subtitle: const Text('Keep context for audit trail'),
                ),
                if (_linkTransaction) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: 'Weekend Trip',
                    decoration: const InputDecoration(
                      labelText: 'Related group/transaction',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Weekend Trip',
                        child: Text('Weekend Trip • Airbnb'),
                      ),
                      DropdownMenuItem(
                        value: 'Roommates',
                        child: Text('Roommates • Utilities'),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note to payer',
                    hintText: 'Add any extra instructions',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Send request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment request sent to $_selectedPayer (demo)'),
        ),
      );
    }
  }
}

