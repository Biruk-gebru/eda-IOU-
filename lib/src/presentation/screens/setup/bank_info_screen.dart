import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _accountNumberError;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  String? _validateAccountNumber(String value) {
    if (value.isEmpty) return null; // optional
    if (value.length < 8) return 'Account number must be at least 8 digits';
    if (value.length > 16) return 'Account number must be at most 16 digits';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Only digits allowed';
    return null;
  }

  Future<void> _submit() async {
    final bankName = _bankNameController.text.trim();
    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    // Validate account number if provided
    if (accountNumber.isNotEmpty) {
      final error = _validateAccountNumber(accountNumber);
      if (error != null) {
        setState(() => _accountNumberError = error);
        return;
      }
      if (bankName.isEmpty || accountName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Bank name and account holder are required with account number')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user == null) return;

      final profileData = <String, dynamic>{
        'id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (bankName.isNotEmpty) profileData['bank_name'] = bankName;
      if (accountName.isNotEmpty) profileData['account_name'] = accountName;
      if (accountNumber.isNotEmpty) {
        profileData['account_number'] = accountNumber;
      }

      await client.from('profiles').upsert(profileData);

      await client.auth.updateUser(
        UserAttributes(data: {'has_bank_info': true}),
      );

      ref.invalidate(authSessionProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.updateUser(
        UserAttributes(data: {'has_bank_info': true}),
      );
      ref.invalidate(authSessionProvider);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return FScaffold(
      header: const FHeader(title: Text('Bank Details')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add your bank details to receive payments. You can skip this and add them later.',
              style: typo.sm.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: 24),
            FTextField(
              control: FTextFieldControl.managed(
                  controller: _accountNameController),
              label: const Text('Account Holder Name'),
              hint: 'Your full name',
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            FTextField(
              control:
                  FTextFieldControl.managed(controller: _bankNameController),
              label: const Text('Bank Name'),
              hint: 'e.g. CBE, Awash, Dashen',
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            FTextField(
              control: FTextFieldControl.managed(
                  controller: _accountNumberController),
              label: const Text('Account Number'),
              hint: '8-16 digits',
              description: _accountNumberError != null
                  ? Text(_accountNumberError!,
                      style: typo.xs.copyWith(color: colors.destructive))
                  : const Text('Ethiopian bank account number (8-16 digits)'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            FButton(
              onPress: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2))
                  : const Text('Save & Continue'),
            ),
            const SizedBox(height: 12),
            FButton(
              variant: FButtonVariant.ghost,
              onPress: _isLoading ? null : _skip,
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
