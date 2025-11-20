import 'package:flutter/material.dart';

class CreateTransactionScreen extends StatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isGroupExpense = true;
  bool _customSplit = false;

  final _participants = [
    _Participant(name: 'You', isPayer: true),
    _Participant(name: 'Liya'),
    _Participant(name: 'Tomas'),
    _Participant(name: 'Sarah'),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New transaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Group'),
                      icon: Icon(Icons.groups_outlined),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Personal'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {_isGroupExpense},
                  onSelectionChanged: (value) =>
                      setState(() => _isGroupExpense = value.first),
                ),
                const SizedBox(height: 16),
                if (_isGroupExpense)
                  DropdownButtonFormField<String>(
                    value: 'Weekend Trip',
                    decoration: const InputDecoration(
                      labelText: 'Group',
                      prefixIcon: Icon(Icons.group_work_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Weekend Trip',
                        child: Text('Weekend Trip'),
                      ),
                      DropdownMenuItem(
                        value: 'Roommates',
                        child: Text('Roommates'),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                if (_isGroupExpense) const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Total amount (ETB)',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Custom split'),
                  subtitle: const Text('Toggle for unequal distribution'),
                  value: _customSplit,
                  onChanged: (value) => setState(() => _customSplit = value),
                ),
                const SizedBox(height: 12),
                ..._participants.map(
                  (participant) => ListTile(
                    leading: Checkbox(
                      value: participant.included,
                      onChanged: (value) {
                        setState(() {
                          participant.included = value ?? true;
                        });
                      },
                    ),
                    title: Text(participant.name),
                    subtitle: _customSplit
                        ? TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              isDense: true,
                            ),
                          )
                        : Text(
                            participant.isPayer ? 'Payer' : 'Included equally',
                          ),
                    trailing: participant.isPayer
                        ? const Icon(Icons.account_balance_wallet_outlined)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildApprovalRules(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit for approval'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalRules() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.rule, color: Colors.black54),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Majority of included participants must approve within 48h. '
              'Auto-cancels if no response.',
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction created (demo)')),
      );
    }
  }
}

class _Participant {
  _Participant({required this.name, this.isPayer = false}) : included = true;

  final String name;
  bool included;
  final bool isPayer;
}
