import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Scaffold(
      backgroundColor: colors.background, // Paper background
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.foreground, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '←',
                        style: typo.lg.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      style: typo.lg.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  // Profile section
                  _label('NAME', colors),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle: typo.sm.copyWith(color: colors.mutedForeground.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.foreground, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.foreground, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.foreground, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _saveName,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.foreground))
                          : Text(
                              'Update name',
                              style: typo.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Banking section
                  Row(
                    children: [
                      Expanded(child: _label('BANK ACCOUNTS', colors)),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BankInfoScreen()),
                          );
                          _loadBankAccounts();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.foreground, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FIcons.plus, size: 14, color: colors.foreground),
                              const SizedBox(width: 6),
                              Text(
                                'Add',
                                style: typo.xs.copyWith(fontWeight: FontWeight.w600, color: colors.foreground),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_bankAccounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No bank accounts added yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _bankAccounts.length; i++)
                            _bankAccountTile(_bankAccounts[i], i == 0, colors, typo),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankAccountTile(Map<String, dynamic> acct, bool isFirst, FColors colors, FTypography typo) {
    final type = acct['bank_type'] as String;
    final isTelebirr = type == 'telebirr';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isFirst ? null : Border(top: BorderSide(color: colors.foreground, width: 1.0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: colors.foreground, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(
              isTelebirr ? FIcons.smartphone : FIcons.landmark,
              size: 16,
              color: colors.foreground,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bankLabel(type),
                  style: typo.lg.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  acct['account_identifier'] as String,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteBankAccount(acct['id'] as String),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: colors.foreground, width: 1.5),
              ),
              child: Icon(
                FIcons.trash2,
                size: 16,
                color: colors.destructive,
              ),
            ),
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

  Widget _label(String text, FColors colors) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: colors.mutedForeground,
        ),
      );
}
