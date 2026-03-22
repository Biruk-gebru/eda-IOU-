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

    return FScaffold(
      header: FHeader.nested(
        title: Text(_name),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        children: [
          // Amount card
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    widget.iOwe ? 'You owe' : 'Owes you',
                    style: typo.sm.copyWith(color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fmt.format(widget.amount),
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: widget.iOwe
                          ? colors.destructive
                          : const Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.iOwe ? 'to $_name' : 'from $_name',
                    style: typo.xs.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Banking info (if they owe you or you owe them)
          if (widget.iOwe && _bankAccounts.isNotEmpty) ...[
            _label('PAY USING', colors, typo),
            const SizedBox(height: 10),
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
                      onPress: () {
                        Clipboard.setData(ClipboardData(
                            text: acct['account_identifier'] as String));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      child: const Icon(FIcons.copy),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Copy the account details above to pay via your banking app',
              style: typo.xs.copyWith(color: colors.mutedForeground),
            ),
          ] else if (widget.iOwe && _bankAccounts.isEmpty && _loaded) ...[
            FAlert(
              icon: const Icon(FIcons.info),
              title: const Text('No banking info'),
              subtitle: Text('$_name has not added banking details yet'),
            ),
          ],

          if (!widget.iOwe) ...[
            _label('REQUEST PAYMENT', colors, typo),
            const SizedBox(height: 10),
            Text(
              '$_name owes you ${_fmt.format(widget.amount)}. '
              'Send them a payment request.',
              style: typo.sm.copyWith(
                  color: colors.mutedForeground, height: 1.5),
            ),
          ],

          const SizedBox(height: 24),

          // Action button
          FButton(
            onPress: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CreatePaymentRequestScreen(),
            )),
            prefix: Icon(widget.iOwe ? FIcons.send : FIcons.handCoins),
            child: Text(widget.iOwe
                ? 'Mark as paid'
                : 'Request payment'),
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
        style: typo.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
          letterSpacing: 0.8,
        ),
      );
}
