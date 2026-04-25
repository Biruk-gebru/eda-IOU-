import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../providers/balance_providers.dart';
import '../../providers/payment_providers.dart';

/// Two modes: "I paid someone" (mark payment) vs "Request payment from someone"
enum PaymentMode { iPaid, requestPayment }

class CreatePaymentRequestScreen extends ConsumerStatefulWidget {
  const CreatePaymentRequestScreen({super.key, this.mode = PaymentMode.requestPayment});

  final PaymentMode mode;

  @override
  ConsumerState<CreatePaymentRequestScreen> createState() =>
      _CreatePaymentRequestScreenState();
}

class _CreatePaymentRequestScreenState
    extends ConsumerState<CreatePaymentRequestScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedUserId;
  String? _selectedUserName;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _isSubmitting = false;

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isIPaid => widget.mode == PaymentMode.iPaid;
  String get _title => _isIPaid ? 'Mark Payment' : 'Request Payment';
  String get _personLabel => _isIPaid ? 'WHO DID YOU PAY?' : 'WHO OWES YOU?';
  String get _buttonLabel => _isIPaid ? 'Mark as paid' : 'Send request';

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final uid = client.auth.currentUser?.id;
      final data = await client
          .from('profiles')
          .select('id, display_name')
          .ilike('display_name', '%$q%')
          .neq('id', uid ?? '')
          .limit(8);
      setState(() => _searchResults = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    setState(() => _searching = false);
  }

  Future<void> _submit() async {
    if (_selectedUserId == null) {
      _snack('Select a person');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Enter a valid amount');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final note = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null;
      if (_isIPaid) {
        // "I paid" = current user is payer, selected user receives
        await repo.createPaymentRequest(
          receiverId: _selectedUserId!,
          amount: amount,
          method: 'direct',
          note: note,
        );
      } else {
        // "Request payment" = selected user is payer, current user receives
        final myId = ref.read(supabaseClientProvider).auth.currentUser!.id;
        await repo.createPaymentRequest(
          payerId: _selectedUserId!,
          receiverId: myId,
          amount: amount,
          method: 'direct',
          note: note,
        );
      }

      ref.invalidate(balancesProvider);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.theme.colors.background,
                border: Border.all(color: context.theme.colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: context.theme.colors.foreground,
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isIPaid ? 'Payment marked' : 'Request sent',
                    style: context.theme.typography.lg.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: context.theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isIPaid
                        ? 'Marked ${_fmt.format(amount)} paid to $_selectedUserName.\nThey need to confirm.'
                        : 'Requested ${_fmt.format(amount)} from $_selectedUserName.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.theme.colors.primary,
                        border: Border.all(color: context.theme.colors.foreground, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: context.theme.colors.foreground,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Done',
                        style: context.theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.theme.colors.foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.foreground, width: 1.5)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FIcons.arrowLeft, size: 20, color: colors.foreground),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _title,
                      style: typo.xl2.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Person search
                    _label(_personLabel, colors, typo),
                    const SizedBox(height: 12),

                    if (_selectedUserId != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.card,
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
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: colors.foreground, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _selectedUserName![0].toUpperCase(),
                                style: typo.sm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _selectedUserName!,
                                style: typo.lg.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedUserId = null;
                                _selectedUserName = null;
                              }),
                              child: Icon(FIcons.x, size: 20, color: colors.foreground),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
                              decoration: InputDecoration(
                                hintText: 'Search by name...',
                                hintStyle: typo.sm.copyWith(color: colors.mutedForeground.withValues(alpha: 0.5)),
                                prefixIcon: Icon(FIcons.search, size: 18, color: colors.mutedForeground),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _searching ? null : _search,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                border: Border.all(color: colors.foreground, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.foreground,
                                    offset: const Offset(3, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _searching
                                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: colors.foreground, strokeWidth: 2))
                                  : Text(
                                      'Search',
                                      style: typo.sm.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.foreground,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (_searchResults.isNotEmpty) const SizedBox(height: 16),
                      for (final u in _searchResults.take(5))
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedUserId = u['id'] as String;
                            _selectedUserName = u['display_name'] as String? ?? 'Unknown';
                            _searchResults = [];
                            _searchController.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: colors.card,
                              border: Border.all(color: colors.foreground, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    u['display_name'] as String? ?? 'Unknown',
                                    style: typo.lg.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colors.foreground,
                                    ),
                                  ),
                                ),
                                Icon(FIcons.plus, size: 20, color: colors.foreground),
                              ],
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 32),

                    // Amount
                    _label('AMOUNT (ETB)', colors, typo),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      enabled: !_isSubmitting,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: typo.xl3.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        letterSpacing: -0.64,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: typo.xl3.copyWith(fontSize: 32, fontWeight: FontWeight.w600, color: colors.mutedForeground.withValues(alpha: 0.5)),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(FIcons.coins, size: 24, color: colors.foreground),
                        ),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Note
                    _label('NOTE (OPTIONAL)', colors, typo),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      enabled: !_isSubmitting,
                      minLines: 2,
                      maxLines: 3,
                      style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
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

                    const SizedBox(height: 48),

                    GestureDetector(
                      onTap: _isSubmitting ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                        child: _isSubmitting
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.foreground, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isIPaid ? FIcons.check : FIcons.send, size: 20, color: colors.foreground),
                                  const SizedBox(width: 10),
                                  Text(
                                    _buttonLabel,
                                    style: typo.lg.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colors.foreground,
                                    ),
                                  ),
                                ],
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

  Widget _label(String text, FColors colors, FTypography typo) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: colors.mutedForeground,
        ),
      );
}
