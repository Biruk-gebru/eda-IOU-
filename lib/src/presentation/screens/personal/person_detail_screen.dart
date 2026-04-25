import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../payments/create_payment_request_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final client = ref.read(supabaseClientProvider);

      // Get profile name
      final profile = await client
          .from('profiles')
          .select('display_name')
          .eq('id', widget.otherUserId)
          .maybeSingle();
      _name = profile?['display_name'] as String? ?? 'Unknown';

      // Get banking accounts
      final accounts = await client
          .from('banking_accounts')
          .select()
          .eq('user_id', widget.otherUserId);
      _bankAccounts = List<Map<String, dynamic>>.from(accounts);

      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

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
                      _name,
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                children: [
                  // Amount card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.card,
                      border: Border.all(color: colors.foreground, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.iOwe ? 'You owe' : 'Owes you',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
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
                            fontSize: 13,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Banking info — always show if available
                  if (_bankAccounts.isNotEmpty) ...[
                    _label(widget.iOwe ? 'PAY USING' : 'THEIR BANKING INFO', colors, typo),
                    const SizedBox(height: 12),
                    Container(
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
                      child: Column(
                        children: [
                          for (var i = 0; i < _bankAccounts.length; i++) ...[
                            if (i > 0) Container(height: 1.5, color: colors.foreground),
                            _buildBankTile(_bankAccounts[i], colors, typo),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Copy the account details above to pay via your banking app',
                      style: GoogleFonts.inter(fontSize: 13, color: colors.mutedForeground),
                    ),
                  ] else if (_bankAccounts.isEmpty && _loaded) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.secondary,
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
                          Icon(FIcons.info, size: 24, color: colors.foreground),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No banking info',
                                  style: typo.lg.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colors.foreground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_name has not added banking details yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!widget.iOwe) ...[
                    const SizedBox(height: 32),
                    _label('REQUEST PAYMENT', colors, typo),
                    const SizedBox(height: 12),
                    Text(
                      '$_name owes you ${_fmt.format(widget.amount)}.\nSend them a payment request.',
                      style: typo.lg.copyWith(
                        fontSize: 16,
                        color: colors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Action button
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CreatePaymentRequestScreen(
                        mode: widget.iOwe ? PaymentMode.iPaid : PaymentMode.requestPayment,
                      ),
                    )),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.iOwe ? FIcons.send : FIcons.handCoins, size: 20, color: colors.foreground),
                          const SizedBox(width: 10),
                          Text(
                            widget.iOwe ? 'Mark as paid' : 'Request payment',
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
          ],
        ),
      ),
    );
  }

  Widget _buildBankTile(Map<String, dynamic> acct, FColors colors, FTypography typo) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            acct['bank_type'] == 'telebirr' ? FIcons.smartphone : FIcons.landmark,
            size: 24,
            color: colors.foreground,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bankLabel(acct['bank_type'] as String),
                  style: typo.lg.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  acct['account_identifier'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: acct['account_identifier'] as String));
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
    );
  }

  String _bankLabel(String type) => switch (type) {
        'telebirr' => 'Telebirr',
        'cbe' => 'CBE',
        'zemen' => 'Zemen Bank',
        _ => type,
      };

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
