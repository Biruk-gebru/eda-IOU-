import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
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
        _navigateAway();
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
    if (mounted) {
      setState(() => _isLoading = false);
      _navigateAway();
    }
  }

  void _navigateAway() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // During onboarding — replace entire stack with AuthGate
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: colors.background, // Paper background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  if (canPop) ...[
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
                  ],
                  Expanded(
                    child: Text(
                      'Add Banking Info',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a bank account to receive payments.\nYou can add more later from Settings.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.mutedForeground,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bank selection
                    Text(
                      'SELECT BANK',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final bank in _banks) _bankChip(bank, colors, typo),
                      ],
                    ),

                    if (_selectedBank != null) ...[
                      const SizedBox(height: 32),

                      // Account holder name
                      Text(
                        'ACCOUNT HOLDER NAME',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _accountNameController,
                        enabled: !_isLoading,
                        textCapitalization: TextCapitalization.words,
                        style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
                        decoration: InputDecoration(
                          hintText: 'Your full name',
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
                      const SizedBox(height: 24),

                      // Bank-specific identifier
                      Text(
                        _selectedBank!.label.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _identifierController,
                        enabled: !_isLoading,
                        keyboardType: _selectedBank!.digitsOnly ? TextInputType.number : TextInputType.text,
                        inputFormatters: [
                          if (_selectedBank!.digitsOnly) FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_selectedBank!.maxLen),
                        ],
                        style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
                        decoration: InputDecoration(
                          hintText: _selectedBank!.hint,
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
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedBank!.minLen}-${_selectedBank!.maxLen} ${_selectedBank!.digitsOnly ? "digits" : "characters"}',
                        style: GoogleFonts.inter(fontSize: 12, color: colors.mutedForeground),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.destructive,
                          border: Border.all(color: colors.foreground, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colors.foreground,
                              offset: const Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(FIcons.circleAlert, color: colors.foreground, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: typo.sm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    GestureDetector(
                      onTap: _isLoading || _selectedBank == null ? null : _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          border: Border.all(color: colors.foreground, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colors.foreground,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.foreground))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FIcons.check, size: 20, color: colors.foreground),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Save',
                                    style: typo.lg.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colors.foreground,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isLoading ? null : _skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: colors.foreground, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Skip for now',
                          style: typo.lg.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.card : Colors.transparent,
          border: Border.all(color: colors.foreground, width: 1.5),
          boxShadow: selected ? [
            BoxShadow(
              color: colors.foreground,
              offset: const Offset(2, 2),
            )
          ] : null,
        ),
        child: Text(
          bank.name,
          style: typo.sm.copyWith(
            color: colors.foreground,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
