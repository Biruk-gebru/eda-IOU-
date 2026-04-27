import 'package:another_telephony/telephony.dart';

class SmsMatch {
  final String reference;
  final double amount;
  final String bankType;
  final String type; // 'DEBIT' | 'CREDIT'
  final DateTime timestamp;

  const SmsMatch({
    required this.reference,
    required this.amount,
    required this.bankType,
    required this.type,
    required this.timestamp,
  });
}

class _SmsPattern {
  final String bankType;
  final List<String> senderCodes;
  final RegExp regex;
  final String type; // 'DEBIT' | 'CREDIT'

  const _SmsPattern({
    required this.bankType,
    required this.senderCodes,
    required this.regex,
    required this.type,
  });
}

class SmsParserService {
  static final _telephony = Telephony.instance;

  // Zero-width / invisible Unicode characters that silently break keyword
  // matching even when text looks correct on screen.
  // ​ ZWSP, ‌ ZWNJ, ‍ ZWJ, ﻿ BOM/ZWNBSP,
  // ­ soft-hyphen, ⁠ word-joiner, ⁡-⁤ invisible operators
  static final _invisibleChars = RegExp(
    '[​‌‍﻿­⁠⁡⁢⁣⁤]',
  );

  // Non-breaking / narrow space variants — normalize to regular ASCII space.
  //   NBSP,   narrow NBSP,   figure space,
  //   punctuation space,   thin space
  static final _nbspChars = RegExp(
    '[     ]',
  );

  static final _patterns = <_SmsPattern>[
    // ── CBE ───────────────────────────────────────────────────────────────────
    _SmsPattern(
      bankType: 'cbe',
      senderCodes: ['CBE'],
      type: 'CREDIT',
      regex: RegExp(
        r'(?:Account|Acct)\s+(?<account>[\d\*]+).*?credited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'cbe',
      senderCodes: ['CBE'],
      type: 'DEBIT',
      regex: RegExp(
        r'(?:Account|Acct)\s+(?<account>[\d\*]+).*?debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'cbe',
      senderCodes: ['CBE'],
      type: 'CREDIT',
      regex: RegExp(
        r'credited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'cbe',
      senderCodes: ['CBE'],
      type: 'DEBIT',
      regex: RegExp(
        r'debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'cbe',
      senderCodes: ['CBE'],
      type: 'DEBIT',
      regex: RegExp(
        r'transfered\s+ETB\s?(?<amount>[\d,.]+)\s+to.*?from\s+your\s+account\s+(?<account>[\d\*]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'cbe',
      senderCodes: ['CBE'],
      type: 'DEBIT',
      regex: RegExp(
        r'(?:Account|Acct)\s+(?<account>[\d\*]+).*?has\s+been\s+debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Current\s+Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?(id=|BranchReceipt/)(?<reference>FT\w+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),

    // ── Telebirr ──────────────────────────────────────────────────────────────
    _SmsPattern(
      bankType: 'telebirr',
      senderCodes: ['127'],
      type: 'DEBIT',
      regex: RegExp(
        r'transferred\s+ETB\s?(?<amount>[\d,.]+)\s+to\s+(?<receiver>[^(]+?)\s*\(.*?transaction\s+number\s+is\s+(?<reference>[A-Z0-9]+).*?balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'telebirr',
      senderCodes: ['127'],
      type: 'DEBIT',
      regex: RegExp(
        r'transferred\s+ETB\s?(?<amount>[\d,.]+).*?from\s+your\s+telebirr\s+account\s+(?<account>\d+)\s+to\s+(?<receiver>.+?)\s+account\s+number\s+(?<bankAccount>\d+).*?telebirr\s+transaction\s+number\s*is\s*(?<reference>[A-Z0-9]+).*?balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'telebirr',
      senderCodes: ['127'],
      type: 'DEBIT',
      regex: RegExp(
        r'paid\s+ETB\s?(?<amount>[\d,.]+)\s+for\s+goods\s+purchased\s+from\s+(?<receiver>.+?)\s+on.*?transaction\s+number\s+is\s+(?<reference>[A-Z0-9]+).*?balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'telebirr',
      senderCodes: ['127'],
      type: 'DEBIT',
      regex: RegExp(
        r'paid\s+ETB\s?(?<amount>[\d,.]+)\s+to\s+(?<receiver>.+?)\s*(?:;|,\s*Bill).*?transaction\s+number\s+is\s+(?<reference>[A-Z0-9]+).*?balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'telebirr',
      senderCodes: ['127'],
      type: 'CREDIT',
      regex: RegExp(
        r'received\s+ETB\s?(?<amount>[\d,.]+)'
        r'.*?\s+from\s+(?<sender>.+?)\s+on\s+'
        r'(?<date>\d{1,2}[\/]\d{1,2}[\/]\d{4}\s+\d{1,2}:\d{2}:\d{2})'
        r'.*?transaction\s+number\s+is\s*(?<reference>[A-Z0-9]+)'
        r'.*?balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'telebirr',
      senderCodes: ['127'],
      type: 'CREDIT',
      regex: RegExp(
        r'received\s+ETB\s?(?<amount>[\d,.]+)\s+by\s+transaction\s+number\s*(?<reference>[A-Z0-9]+).*?from\s+.*?\s+to\s+your\s+telebirr\s+account.*?balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),

    // ── Zemen Bank ────────────────────────────────────────────────────────────
    _SmsPattern(
      bankType: 'zemen',
      senderCodes: ['Zemen', 'Zemen Bank', 'ZemenBank'],
      type: 'CREDIT',
      regex: RegExp(
        r'(?:account|a\/c)\s+(?<account>[\dx*]+).*?credited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?reference\s+(?<reference>[A-Z0-9]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'zemen',
      senderCodes: ['Zemen', 'Zemen Bank', 'ZemenBank'],
      type: 'DEBIT',
      regex: RegExp(
        r'(?:account|a\/c)\s+(?<account>[\dx*]+).*?debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?reference\s+(?<reference>[A-Z0-9]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
    _SmsPattern(
      bankType: 'zemen',
      senderCodes: ['Zemen', 'Zemen Bank', 'ZemenBank'],
      type: 'DEBIT',
      regex: RegExp(
        r'Birr\s+(?<amount>[\d,.]+)\s+ATM\s+cash\s+withdrawal.*?A\/c\s+(?:No\.?)?\s+(?<account>[\dx*]+).*?Bal\.\s+is\s+Birr\s?(?<balance>[\d,.]+)',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
    ),
  ];

  Future<bool> requestPermission() async {
    final granted = await _telephony.requestPhoneAndSmsPermissions;
    return granted ?? false;
  }

  Future<SmsMatch?> findDebitSms({
    required String bankType,
    required double amount,
    Duration maxAge = const Duration(hours: 24),
  }) =>
      _scan(bankType: bankType, amount: amount, maxAge: maxAge, type: 'DEBIT');

  Future<SmsMatch?> findCreditSms({
    required String bankType,
    required double amount,
    Duration maxAge = const Duration(hours: 24),
  }) =>
      _scan(bankType: bankType, amount: amount, maxAge: maxAge, type: 'CREDIT');

  Future<SmsMatch?> _scan({
    required String bankType,
    required double amount,
    required Duration maxAge,
    required String type,
  }) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final patterns = _patterns
        .where((p) => p.bankType == bankType && p.type == type)
        .toList();

    for (final sms in messages) {
      final date = sms.date ?? 0;
      if (date < cutoff) break; // sorted DESC, once too old stop

      final address = sms.address ?? '';
      final body = _sanitizeBody(sms.body ?? '');

      final relevantPatterns = patterns.where(
        (p) => p.senderCodes.any(
          (code) => address.toLowerCase().contains(code.toLowerCase()),
        ),
      );

      for (final pattern in relevantPatterns) {
        final match = pattern.regex.firstMatch(body);
        if (match == null) continue;

        final rawAmount = _cleanNumber(
          match.groupNames.contains('amount')
              ? match.namedGroup('amount')
              : null,
        );
        final parsedAmount = double.tryParse(rawAmount ?? '');
        if (parsedAmount == null) continue;

        // ±1 ETB tolerance to handle formatting differences
        if ((parsedAmount - amount).abs() > 1.0) continue;

        final reference = match.groupNames.contains('reference')
            ? match.namedGroup('reference')
            : null;
        if (reference == null) continue;

        return SmsMatch(
          reference: reference,
          amount: parsedAmount,
          bankType: bankType,
          type: type,
          timestamp: DateTime.fromMillisecondsSinceEpoch(date),
        );
      }
    }
    return null;
  }

  // Strips hidden characters from bank SMS bodies before regex matching.
  // These characters are invisible on screen but break keyword matching.
  static String _sanitizeBody(String text) {
    // 1. Remove zero-width spaces, BOM, soft hyphen, and invisible operators
    String s = text.replaceAll(_invisibleChars, '');
    // 2. Normalize non-breaking / narrow spaces to regular ASCII space
    s = s.replaceAll(_nbspChars, ' ');
    // 3. Normalize \r\n and lone \r to \n (dotAll handles \n fine)
    s = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // 4. Collapse runs of spaces and tabs to a single space
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
    return s.trim();
  }

  static String? _cleanNumber(String? input) {
    if (input == null) return null;
    String cleaned = input.replaceAll(',', '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9.]$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\.+$'), '');
    return cleaned;
  }
}
