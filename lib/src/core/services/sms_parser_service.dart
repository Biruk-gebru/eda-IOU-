import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'sms_permission_granted';

  // Zero-width / invisible Unicode characters that silently break keyword
  // matching even when text looks correct on screen.
  static final _invisibleChars = RegExp(
    '[​‌‍﻿­⁠⁡⁢⁣⁤]',
  );

  // Non-breaking / narrow space variants — normalize to regular ASCII space.
  static final _nbspChars = RegExp(
    '[     ]',
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

  /// Requests READ_SMS + PHONE permissions. Returns true if granted.
  /// On non-Android devices returns false immediately without showing any dialog.
  /// Caches the result so the system dialog is only ever shown once.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    final cached = await _storage.read(key: _permKey);
    if (cached == 'true') return true;
    final granted = await _telephony.requestPhoneAndSmsPermissions ?? false;
    if (granted) await _storage.write(key: _permKey, value: 'true');
    return granted;
  }

  /// Searches for a DEBIT SMS matching [amount] from [bankType].
  ///
  /// [anchor] is the datetime the user says they sent the payment.
  /// The search window is [anchor - before] to [anchor + after].
  /// Defaults: 12 h before and 1 h after the anchor.
  Future<SmsMatch?> findDebitSms({
    required String bankType,
    required double amount,
    required DateTime anchor,
    Duration before = const Duration(hours: 12),
    Duration after = const Duration(hours: 1),
  }) {
    if (!Platform.isAndroid) return Future.value(null);
    return _scan(
      bankType: bankType,
      amount: amount,
      type: 'DEBIT',
      anchor: anchor,
      before: before,
      after: after,
    );
  }

  /// Searches for a CREDIT SMS matching [amount] from [bankType].
  ///
  /// For the receiver confirming receipt, [anchor] defaults to now and
  /// [before] defaults to 7 days (payment may have arrived days ago).
  Future<SmsMatch?> findCreditSms({
    required String bankType,
    required double amount,
    DateTime? anchor,
    Duration before = const Duration(days: 7),
    Duration after = const Duration(hours: 1),
  }) {
    if (!Platform.isAndroid) return Future.value(null);
    return _scan(
      bankType: bankType,
      amount: amount,
      type: 'CREDIT',
      anchor: anchor ?? DateTime.now(),
      before: before,
      after: after,
    );
  }

  Future<SmsMatch?> _scan({
    required String bankType,
    required double amount,
    required String type,
    required DateTime anchor,
    required Duration before,
    required Duration after,
  }) async {
    final lowerBound = anchor.subtract(before).millisecondsSinceEpoch;
    final upperBound = anchor.add(after).millisecondsSinceEpoch;

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final patterns = _patterns
        .where((p) => p.bankType == bankType && p.type == type)
        .toList();

    for (final sms in messages) {
      final date = sms.date ?? 0;
      if (date > upperBound) continue; // newer than anchor+after, skip
      if (date < lowerBound) break;    // older than anchor-before, stop (DESC)

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
  static String _sanitizeBody(String text) {
    String s = text.replaceAll(_invisibleChars, '');
    s = s.replaceAll(_nbspChars, ' ');
    s = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
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
