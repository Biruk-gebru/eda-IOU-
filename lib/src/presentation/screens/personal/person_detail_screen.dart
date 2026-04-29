import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/services/sms_parser_service.dart';
import '../../../domain/entities/payment_request.dart';
import '../../providers/auth_providers.dart';
import '../../providers/balance_providers.dart';
import '../../providers/payment_providers.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({
    super.key,
    required this.otherUserId,
    required this.amount,
    required this.iOwe,
  });

  final String otherUserId;
  final double amount;
  final bool iOwe;

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  String _name = '...';
  List<Map<String, dynamic>> _bankAccounts = [];
  bool _loaded = false;
  late final TextEditingController _amountCtl;
  bool _submitting = false;
  final _acting = <String>{};

  // SMS verification state
  String? _selectedPayerBank;      // which bank the payer is sending from
  String? _selectedReceiverBankType; // which of receiver's accounts is being targeted
  String? _myBankType;             // current user's bank (for receiver-side scan)

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _amountCtl = TextEditingController(text: widget.amount.toStringAsFixed(0));
    _loadDetails();
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await client
          .from('profiles')
          .select('display_name')
          .eq('id', widget.otherUserId)
          .maybeSingle();
      _name = profile?['display_name'] as String? ?? 'Unknown';

      if (widget.iOwe) {
        final accounts = await client
            .from('banking_accounts')
            .select()
            .eq('user_id', widget.otherUserId);
        _bankAccounts = List<Map<String, dynamic>>.from(accounts);
        if (_bankAccounts.length == 1) {
          _selectedReceiverBankType = _bankAccounts.first['bank_type'] as String?;
        }
      }

      // Load current user's primary bank for receiver-side SMS scan
      final currentUserId = client.auth.currentUser!.id;
      final myAccounts = await client
          .from('banking_accounts')
          .select()
          .eq('user_id', currentUserId);
      if ((myAccounts as List).isNotEmpty) {
        _myBankType = myAccounts.first['bank_type'] as String?;
      }

      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtl.text.trim());
    if (amount == null || amount <= 0) return;

    if (widget.iOwe && _selectedPayerBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the bank you sent from')),
      );
      return;
    }

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repo = ref.read(paymentRepositoryProvider);

      if (widget.iOwe) {
        final svc = SmsParserService();
        final granted = await svc.requestPermission();
        if (!granted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('SMS permission required to verify payment')),
          );
          if (mounted) setState(() => _submitting = false);
          return;
        }
        final match = await svc.findDebitSms(
          bankType: _selectedPayerBank!,
          amount: amount,
        );
        if (match == null) {
          messenger.showSnackBar(SnackBar(
            content: Text(
              'No transaction found for ${_fmt.format(amount)} from ${_bankLabel(_selectedPayerBank!)} in the last 24 hours',
            ),
          ));
          if (mounted) setState(() => _submitting = false);
          return;
        }
        await repo.createPaymentRequest(
          receiverId: widget.otherUserId,
          amount: amount,
          smsReference: match.reference,
          payerBankType: _selectedPayerBank,
          receiverBankType: _selectedReceiverBankType,
        );
        ref.invalidate(pendingRequestsBetweenProvider(widget.otherUserId));
        messenger.showSnackBar(SnackBar(
          content: Text('Marked as paid — ref: ${match.reference}'),
        ));
      } else {
        // Creditor requesting payment — no SMS scan needed
        final me = ref.read(supabaseClientProvider).auth.currentUser!.id;
        await repo.createPaymentRequest(
          receiverId: me,
          payerId: widget.otherUserId,
          amount: amount,
        );
        ref.invalidate(pendingRequestsBetweenProvider(widget.otherUserId));
        messenger.showSnackBar(SnackBar(
          content: Text('Payment request sent to $_name'),
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirm(PaymentRequest req) async {
    final bankType = req.receiverBankType ?? _myBankType;
    if (bankType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a bank account in Settings to verify')),
      );
      return;
    }

    setState(() => _acting.add(req.id));
    final messenger = ScaffoldMessenger.of(context);

    try {
      final svc = SmsParserService();
      final granted = await svc.requestPermission();
      if (!granted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('SMS permission required to verify payment')),
        );
        if (mounted) setState(() => _acting.remove(req.id));
        return;
      }
      final match = await svc.findCreditSms(bankType: bankType, amount: req.amount);
      if (match == null) {
        messenger.showSnackBar(SnackBar(
          content: Text(
            'No incoming transaction found for ${_fmt.format(req.amount)} in your ${_bankLabel(bankType)} account',
          ),
        ));
        if (mounted) setState(() => _acting.remove(req.id));
        return;
      }
      await ref.read(paymentRepositoryProvider).confirmPayment(req.id);
      ref.invalidate(pendingRequestsBetweenProvider(widget.otherUserId));
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(balancesProvider);
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Payment confirmed')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _acting.remove(req.id));
    }
  }

  Future<void> _reject(String requestId) async {
    setState(() => _acting.add(requestId));
    try {
      await ref.read(paymentRepositoryProvider).rejectPayment(requestId);
      ref.invalidate(pendingRequestsBetweenProvider(widget.otherUserId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _acting.remove(requestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final me = ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';
    final requestsAsync =
        ref.watch(pendingRequestsBetweenProvider(widget.otherUserId));

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: colors.foreground, width: 1.5)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FIcons.arrowLeft,
                          size: 20, color: colors.foreground),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _name,
                    style: typo.xl2.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                children: [
                  // ── Balance card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.card,
                      border:
                          Border.all(color: colors.foreground, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: colors.foreground,
                            offset: const Offset(4, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.iOwe ? 'YOU OWE' : 'OWES YOU',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _fmt.format(widget.amount),
                          style: typo.xl3.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: widget.iOwe
                                ? colors.destructive
                                : const Color(0xFF34D399),
                            letterSpacing: -0.72,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.iOwe ? 'to $_name' : 'from $_name',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Pending payment requests ──────────────────────────────
                  requestsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (requests) {
                      if (requests.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PENDING PAYMENTS',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...requests.map((req) {
                            final iAmReceiver = req.receiverId == me;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.card,
                                border: Border.all(
                                    color: colors.foreground, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: colors.foreground,
                                      offset: const Offset(3, 3)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _fmt.format(req.amount),
                                          style: typo.lg.copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: colors.foreground,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: iAmReceiver
                                              ? colors.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                              color: colors.foreground,
                                              width: 1.5),
                                        ),
                                        child: Text(
                                          iAmReceiver
                                              ? 'NEEDS APPROVAL'
                                              : 'PENDING',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: colors.foreground,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (req.smsReference != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ref: ${req.smsReference}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                  if (req.note != null &&
                                      req.note!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      req.note!,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: colors.mutedForeground),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  if (iAmReceiver)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _acting.contains(req.id)
                                                ? null
                                                : () => _reject(req.id),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: colors.foreground,
                                                    width: 1.5),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Reject',
                                                style: typo.sm.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.foreground,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _acting.contains(req.id)
                                                ? null
                                                : () => _confirm(req),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                color: colors.primary,
                                                border: Border.all(
                                                    color: colors.foreground,
                                                    width: 1.5),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: colors.foreground,
                                                      offset:
                                                          const Offset(2, 2)),
                                                ],
                                              ),
                                              alignment: Alignment.center,
                                              child: _acting.contains(req.id)
                                                  ? SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                          color: colors.foreground,
                                                          strokeWidth: 2),
                                                    )
                                                  : Text(
                                                      'Confirm received',
                                                      style: typo.sm.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: colors.foreground,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Awaiting confirmation from $_name',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: colors.mutedForeground),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),

                  // ── Banking info (debtor only) ─────────────────────────────
                  if (widget.iOwe && _loaded) ...[
                    // "PAYING FROM" bank selector
                    Text(
                      'PAYING FROM',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['cbe', 'telebirr', 'zemen'].map((bank) {
                        final selected = _selectedPayerBank == bank;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPayerBank = bank),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: bank == 'zemen' ? 0 : 8,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? colors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: colors.foreground,
                                  width: selected ? 2.0 : 1.5,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                            color: colors.foreground,
                                            offset: const Offset(2, 2))
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _bankLabel(bank),
                                style: typo.sm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    if (_bankAccounts.isNotEmpty) ...[
                      Text(
                        'PAY USING',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.card,
                          border: Border.all(
                              color: colors.foreground, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: colors.foreground,
                                offset: const Offset(3, 3)),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _bankAccounts.length; i++) ...[
                              if (i > 0)
                                Container(height: 1.5, color: colors.foreground),
                              _bankTile(_bankAccounts[i], colors, typo),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          border: Border.all(
                              color: colors.foreground, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(FIcons.info,
                                size: 20, color: colors.foreground),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$_name has not added banking details yet',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: colors.mutedForeground),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // ── Action section ────────────────────────────────────────
                  Text(
                    widget.iOwe ? 'MARK AS PAID' : 'REQUEST PAYMENT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.iOwe
                        ? 'After paying $_name externally, record the payment here. They\'ll confirm receipt.'
                        : '$_name owes you ${_fmt.format(widget.amount)}. Enter the amount to request.',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.mutedForeground,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  _amountField(colors, typo),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _submitting ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        border:
                            Border.all(color: colors.foreground, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: colors.foreground,
                              offset: const Offset(4, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _submitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: colors.foreground, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.iOwe
                                      ? FIcons.send
                                      : FIcons.handCoins,
                                  size: 18,
                                  color: colors.foreground,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.iOwe
                                      ? 'Mark as paid'
                                      : 'Request payment',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountField(FColors colors, FTypography typo) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.foreground, width: 1.5),
    );
    return TextField(
      controller: _amountCtl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: typo.xl.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
        letterSpacing: -0.48,
      ),
      decoration: InputDecoration(
        prefixText: 'ETB  ',
        prefixStyle: typo.sm.copyWith(
            fontWeight: FontWeight.w500, color: colors.mutedForeground),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
      ),
    );
  }

  Widget _bankTile(
      Map<String, dynamic> acct, FColors colors, FTypography typo) {
    final bankType = acct['bank_type'] as String;
    final isSelected = _selectedReceiverBankType == bankType;
    return GestureDetector(
      onTap: () => setState(() => _selectedReceiverBankType = bankType),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              bankType == 'telebirr' ? FIcons.smartphone : FIcons.landmark,
              size: 24,
              color: colors.foreground,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bankLabel(bankType),
                    style: typo.lg.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    acct['account_identifier'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(FIcons.check, size: 18, color: colors.foreground),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: acct['account_identifier'] as String));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.foreground, width: 1.5),
                ),
                child: Icon(FIcons.copy, size: 18, color: colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bankLabel(String type) => switch (type) {
        'telebirr' => 'Telebirr',
        'cbe' => 'CBE',
        'zemen' => 'Zemen Bank',
        _ => type,
      };
}
