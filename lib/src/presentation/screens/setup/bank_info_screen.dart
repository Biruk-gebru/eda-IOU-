import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';

/// Ethiopian bank definitions with validation rules.
class _BankDef {
  final String id;
  final String name;
  final String label; // what the identifier field is called
  final String hint;
  final int minLen;
  final int maxLen;
  final bool digitsOnly;

  const _BankDef({
    required this.id,
    required this.name,
    required this.label,
    required this.hint,
    required this.minLen,
    required this.maxLen,
    this.digitsOnly = true,
  });

  String? validate(String value) {
    if (value.isEmpty) return '$label is required';
    if (digitsOnly && !RegExp(r'^\d+$').hasMatch(value)) {
      return '$label must be digits only';
    }
    if (value.length < minLen) return '$label must be at least $minLen characters';
    if (value.length > maxLen) return '$label must be at most $maxLen characters';
    return null;
  }
}

const _banks = [
  _BankDef(
    id: 'telebirr',
    name: 'Telebirr',
    label: 'Phone number',
    hint: '09XXXXXXXX',
    minLen: 10,
    maxLen: 10,
  ),
  _BankDef(
    id: 'cbe',
    name: 'CBE (Commercial Bank of Ethiopia)',
    label: 'Account number',
    hint: '1000XXXXXXXXXX',
    minLen: 13,
    maxLen: 16,
  ),
  _BankDef(
    id: 'zemen',
    name: 'Zemen Bank',
    label: 'Account number',
    hint: 'Enter account number',
    minLen: 10,
    maxLen: 16,
  ),
];

class BankInfoScreen extends ConsumerStatefulWidget {
  const BankInfoScreen({super.key});

  @override
  ConsumerState<BankInfoScreen> createState() => _BankInfoScreenState();
}

class _BankInfoScreenState extends ConsumerState<BankInfoScreen> {
  _BankDef? _selectedBank;
  final _identifierController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedBank == null) {
      setState(() => _error = 'Select a bank');
      return;
    }

    final identifier = _identifierController.text.trim();
    final validationError = _selectedBank!.validate(identifier);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final accountName = _accountNameController.text.trim();
    if (accountName.isEmpty) {
      setState(() => _error = 'Account holder name is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Insert into banking_accounts table
      await client.from('banking_accounts').upsert({
        'user_id': userId,
        'bank_type': _selectedBank!.id,
        'account_identifier': identifier,
        'account_name': accountName,
        'is_primary': true,
      });

      // Mark setup as complete
      await client.auth.updateUser(
        UserAttributes(data: {'has_bank_info': true}),
      );

      ref.invalidate(currentUserProvider);
      ref.invalidate(authSessionProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banking info saved')),
        );
        // If this is part of onboarding (no back button), pop will be handled by AuthGate
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
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
      header: FHeader.nested(
        title: const Text('Add Banking Info'),
        prefixes: [
          if (Navigator.of(context).canPop())
            FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a bank account to receive payments.\nYou can add more later from Settings.',
              style:
                  typo.sm.copyWith(color: colors.mutedForeground, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Bank selection
            Text('SELECT BANK',
                style: typo.xs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final bank in _banks) _bankChip(bank, colors, typo),
              ],
            ),

            if (_selectedBank != null) ...[
              const SizedBox(height: 24),

              // Account holder name
              FTextField(
                control: FTextFieldControl.managed(
                    controller: _accountNameController),
                label: const Text('Account holder name'),
                hint: 'Your full name',
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Bank-specific identifier
              FTextField(
                control: FTextFieldControl.managed(
                    controller: _identifierController),
                label: Text(_selectedBank!.label),
                hint: _selectedBank!.hint,
                description: Text(
                    '${_selectedBank!.minLen}-${_selectedBank!.maxLen} ${_selectedBank!.digitsOnly ? "digits" : "characters"}'),
                keyboardType: _selectedBank!.digitsOnly
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: [
                  if (_selectedBank!.digitsOnly)
                    FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_selectedBank!.maxLen),
                ],
                enabled: !_isLoading,
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              FAlert(
                variant: FAlertVariant.destructive,
                title: Text(_error!),
              ),
            ],

            const SizedBox(height: 28),
            FButton(
              onPress: _isLoading || _selectedBank == null ? null : _submit,
              prefix: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18, child: FCircularProgress())
                  : const Icon(FIcons.check),
              child: const Text('Save'),
            ),
            const SizedBox(height: 10),
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

  Widget _bankChip(_BankDef bank, FColors colors, FTypography typo) {
    final selected = _selectedBank?.id == bank.id;
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () => setState(() {
                _selectedBank = bank;
                _identifierController.clear();
                _error = null;
              }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.card : colors.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? colors.foreground.withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Text(
          bank.name,
          style: typo.sm.copyWith(
            color: selected ? colors.foreground : colors.mutedForeground,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
