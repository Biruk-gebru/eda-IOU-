import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
        await showFDialog(
          context: context,
          builder: (ctx, style, animation) => FDialog(
            animation: animation,
            title: Text(_isIPaid ? 'Payment marked' : 'Request sent'),
            body: Text(_isIPaid
                ? 'Marked ${_fmt.format(amount)} paid to $_selectedUserName.\nThey need to confirm.'
                : 'Requested ${_fmt.format(amount)} from $_selectedUserName.'),
            actions: [
              FButton(
                onPress: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
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

    return FScaffold(
      header: FHeader.nested(
        title: Text(_title),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Person search
            _label(_personLabel, colors, typo),
            const SizedBox(height: 10),

            if (_selectedUserId != null)
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedUserName![0].toUpperCase(),
                          style: typo.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_selectedUserName!,
                            style: typo.sm.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colors.foreground)),
                      ),
                      FButton.icon(
                        onPress: () =>
                            setState(() {
                              _selectedUserId = null;
                              _selectedUserName = null;
                            }),
                        child: Icon(FIcons.x,
                            size: 16, color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: FTextField(
                      control: FTextFieldControl.managed(
                          controller: _searchController),
                      hint: 'Search by name...',
                      prefixBuilder: (c, s, v) => FTextField.prefixIconBuilder(
                          c, s, v, const Icon(FIcons.search)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: _searching ? null : _search,
                    child: _searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2))
                        : const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final u in _searchResults.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FTile(
                    title: Text(u['display_name'] as String? ?? 'Unknown'),
                    onPress: () => setState(() {
                      _selectedUserId = u['id'] as String;
                      _selectedUserName =
                          u['display_name'] as String? ?? 'Unknown';
                      _searchResults = [];
                      _searchController.clear();
                    }),
                    suffix: const Icon(FIcons.plus),
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // Amount
            _label('AMOUNT (ETB)', colors, typo),
            const SizedBox(height: 10),
            FTextField(
              control:
                  FTextFieldControl.managed(controller: _amountController),
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSubmitting,
              prefixBuilder: (c, s, v) =>
                  FTextField.prefixIconBuilder(c, s, v, const Icon(FIcons.coins)),
            ),

            const SizedBox(height: 20),

            // Note
            _label('NOTE (OPTIONAL)', colors, typo),
            const SizedBox(height: 10),
            FTextField(
              control: FTextFieldControl.managed(controller: _noteController),
              hint: 'Add a note...',
              minLines: 2,
              maxLines: 3,
              enabled: !_isSubmitting,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: _isSubmitting ? null : _submit,
                prefix: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2))
                    : Icon(_isIPaid ? FIcons.check : FIcons.send),
                child: Text(_buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
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
