import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_providers.dart';

class BankInfoScreen extends ConsumerStatefulWidget {
  const BankInfoScreen({super.key});

  @override
  ConsumerState<BankInfoScreen> createState() => _BankInfoScreenState();
}

class _BankInfoScreenState extends ConsumerState<BankInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user == null) return;

      final bankName = _bankNameController.text.trim();
      final accountName = _accountNameController.text.trim();
      final accountNumber = _accountNumberController.text.trim();

      // Save to Supabase Profiles
      await client.from('profiles').upsert({
        'id': user.id,
        'bank_name': bankName,
        'account_name': accountName,
        'account_number': accountNumber,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update User Metadata (keep for backward compatibility/fast access if needed)
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'has_bank_info': true,
          },
        ),
      );

      // Refresh session
      ref.refresh(authSessionProvider);
      
      if (mounted) {
        // Navigation will be handled by AuthGate or similar
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Bank Info')),
      body: SingleChildScrollView( // Added for avoiding overflow with new field
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Please provide your bank details to receive payments.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
