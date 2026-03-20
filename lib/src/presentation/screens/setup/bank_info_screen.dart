import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_providers.dart';

class BankInfoScreen extends ConsumerStatefulWidget {
  const BankInfoScreen({super.key});

  @override
  ConsumerState<BankInfoScreen> createState() => _BankInfoScreenState();
}

class _BankInfoScreenState extends ConsumerState<BankInfoScreen> {
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
    final bankName = _bankNameController.text.trim();
    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    if (bankName.isEmpty || accountName.isEmpty || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user == null) return;

      await client.from('profiles').upsert({
        'id': user.id,
        'bank_name': bankName,
        'account_name': accountName,
        'account_number': accountNumber,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await client.auth.updateUser(
        UserAttributes(
          data: {
            'has_bank_info': true,
          },
        ),
      );

      ref.invalidate(authSessionProvider);

      if (mounted) {
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
    return FScaffold(
      header: const FHeader(title: Text('Setup Bank Info')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide your bank details to receive payments.',
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            FTextField(
              control: FTextFieldControl.managed(
                controller: _accountNameController,
              ),
              label: const Text('Account Holder Name'),
              hint: 'Enter your full name',
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            FTextField(
              control: FTextFieldControl.managed(
                controller: _bankNameController,
              ),
              label: const Text('Bank Name'),
              hint: 'e.g. CBE, Awash, Dashen',
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            FTextField(
              control: FTextFieldControl.managed(
                controller: _accountNumberController,
              ),
              label: const Text('Account Number'),
              hint: 'Enter your account number',
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            FButton(
              onPress: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
