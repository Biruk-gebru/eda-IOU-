import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _paymentDetailsController = TextEditingController();
  String _selectedMethod = 'Bank Transfer';

  @override
  void dispose() {
    _nameController.dispose();
    _paymentDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let others know how to settle with you.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Preferred payment method',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Text('Bank Transfer'),
                    ),
                    DropdownMenuItem(
                      value: 'Mobile Money',
                      child: Text('Mobile Money'),
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
                TextFormField(
                  controller: _paymentDetailsController,
                  decoration: InputDecoration(
                    labelText: 'Payment details',
                    hintText: _selectedMethod == 'Bank Transfer'
                        ? 'Bank name, account number'
                        : 'Phone number / instructions',
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  title: const Text('Enable notifications'),
                  subtitle: const Text(
                    'Stay updated with approvals and payments',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Save and continue'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved (demo)')));
    }
  }
}
