import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  bool _isLoading = false;
  bool _loaded = false;
  String? _accountError;

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _loadProfile(dynamic user) {
    if (_loaded || user == null) return;
    _loaded = true;
    _nameController.text = user.displayName ?? '';
    _bankNameController.text = user.bankName ?? '';
    _accountNameController.text = user.accountName ?? '';
    _accountNumberController.text = user.accountNumber ?? '';
  }

  String? _validateAccountNumber(String value) {
    if (value.isEmpty) return null;
    if (value.length < 8) return 'At least 8 digits';
    if (value.length > 16) return 'At most 16 digits';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Only digits allowed';
    return null;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final acctNum = _accountNumberController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required')),
      );
      return;
    }

    if (acctNum.isNotEmpty) {
      final err = _validateAccountNumber(acctNum);
      if (err != null) {
        setState(() => _accountError = err);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('profiles').upsert({
        'id': userId,
        'display_name': name,
        'bank_name': _bankNameController.text.trim().isNotEmpty
            ? _bankNameController.text.trim()
            : null,
        'account_name': _accountNameController.text.trim().isNotEmpty
            ? _accountNameController.text.trim()
            : null,
        'account_number': acctNum.isNotEmpty ? acctNum : null,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final userAsync = ref.watch(currentUserProvider);

    userAsync.whenData((user) => _loadProfile(user));

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Edit Profile'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Text('Profile',
                style: typo.xs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
            FTextField(
              control:
                  FTextFieldControl.managed(controller: _nameController),
              label: const Text('Display Name'),
              hint: 'Your name',
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 28),

            // Banking section
            Text('Banking Info',
                style: typo.xs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text('Used for receiving payments (optional)',
                style: typo.xs.copyWith(color: colors.mutedForeground)),
            const SizedBox(height: 12),
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
              control: FTextFieldControl.managed(
                  controller: _bankNameController),
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
              description: _accountError != null
                  ? Text(_accountError!,
                      style: typo.xs.copyWith(color: colors.destructive))
                  : const Text('Ethiopian bank account (8-16 digits)'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            FButton(
              onPress: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
