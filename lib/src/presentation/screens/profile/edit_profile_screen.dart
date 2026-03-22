import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../setup/bank_info_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _loaded = false;
  List<Map<String, dynamic>> _bankAccounts = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadProfile(dynamic user) {
    if (_loaded || user == null) return;
    _loaded = true;
    _nameController.text = user.displayName ?? '';
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await client
          .from('banking_accounts')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      setState(() => _bankAccounts = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('profiles').upsert({
        'id': userId,
        'display_name': name,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Name updated')));
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

  Future<void> _deleteBankAccount(String id) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('banking_accounts').delete().eq('id', id);
      await _loadBankAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Account removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          // Profile section
          _label('NAME', colors, typo),
          const SizedBox(height: 10),
          FTextField(
            control: FTextFieldControl.managed(controller: _nameController),
            hint: 'Your name',
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
          ),
          const SizedBox(height: 12),
          FButton(
            variant: FButtonVariant.outline,
            onPress: _isLoading ? null : _saveName,
            child: const Text('Update name'),
          ),

          const SizedBox(height: 32),

          // Banking section
          Row(
            children: [
              Expanded(child: _label('BANK ACCOUNTS', colors, typo)),
              FButton(
                variant: FButtonVariant.outline,
                onPress: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BankInfoScreen()),
                  );
                  _loadBankAccounts();
                },
                prefix: const Icon(FIcons.plus),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_bankAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No bank accounts added yet',
                    style: typo.sm.copyWith(color: colors.mutedForeground)),
              ),
            )
          else
            FTileGroup(
              children: [
                for (final acct in _bankAccounts)
                  FTile(
                    prefix: Icon(
                      acct['bank_type'] == 'telebirr'
                          ? FIcons.smartphone
                          : FIcons.landmark,
                      color: colors.mutedForeground,
                    ),
                    title: Text(_bankLabel(acct['bank_type'] as String)),
                    subtitle: Text(acct['account_identifier'] as String),
                    suffix: FButton.icon(
                      onPress: () => _deleteBankAccount(acct['id'] as String),
                      child: Icon(FIcons.trash2,
                          size: 16, color: colors.destructive),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _bankLabel(String type) {
    switch (type) {
      case 'telebirr':
        return 'Telebirr';
      case 'cbe':
        return 'CBE';
      case 'zemen':
        return 'Zemen Bank';
      default:
        return type;
    }
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
