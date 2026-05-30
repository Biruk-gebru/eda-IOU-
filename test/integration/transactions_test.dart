import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  group('Transactions', () {
    late String txId;

    // Creates a personal IOU in setUp, used by vote tests.
    setUp(() async {
      final client = await signInAsBiruk();
      final tx = await client.from('transactions').insert({
        'creator_id': kBirukId,
        'payer_id': kBirukId,
        'total_amount': 300.0,
        'description': '[TEST] Dinner',
        'currency': 'ETB',
        'status': 'pending',
        'timeout_at': DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
      }).select().single();
      txId = tx['id'] as String;

      // Add Abel as a participant (owes 150)
      await client.from('transaction_participants').insert({
        'transaction_id': txId,
        'user_id': kAbelId,
        'amount_due': 150.0,
      });
      await client.auth.signOut();
    });

    tearDown(() async {
      final admin = adminClient();
      await admin.from('transaction_participants').delete().eq('transaction_id', txId);
      await admin.from('transactions').delete().eq('id', txId);
    });

    test('created transaction is visible and has correct fields', () async {
      final client = await signInAsBiruk();
      final tx = await client
          .from('transactions')
          .select()
          .eq('id', txId)
          .single();
      expect(tx['description'], '[TEST] Dinner');
      expect((tx['total_amount'] as num).toDouble(), 300.0);
      expect(tx['status'], 'pending');
      expect(tx['payer_id'], kBirukId);
      await client.auth.signOut();
    });

    test('transaction participants list is correct', () async {
      final client = await signInAsBiruk();
      final parts = await client
          .from('transaction_participants')
          .select()
          .eq('transaction_id', txId);
      expect((parts as List).length, 1);
      expect(parts.first['user_id'], kAbelId);
      expect((parts.first['amount_due'] as num).toDouble(), 150.0);
      await client.auth.signOut();
    });

    test('vote_transaction RPC — approve updates status', () async {
      final client = await signInAsBiruk();

      // Abel votes to approve via admin (simulate Abel's action)
      final admin = adminClient();
      await admin.rpc('vote_transaction', params: {
        'p_transaction_id': txId,
        'p_user_id': kAbelId,
        'p_approve': true,
      });

      // Check participant approval recorded
      final part = await admin
          .from('transaction_participants')
          .select('approved')
          .eq('transaction_id', txId)
          .eq('user_id', kAbelId)
          .single();
      expect(part['approved'], isTrue);
      await client.auth.signOut();
    });

    test('transaction appears in getTransactions list for creator', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('transactions')
          .select()
          .or('creator_id.eq.$kBirukId,payer_id.eq.$kBirukId')
          .order('created_at', ascending: false);
      final ids = (rows as List).map((r) => r['id'] as String).toList();
      expect(ids, contains(txId));
      await client.auth.signOut();
    });

    test('expired transaction can be cancelled', () async {
      final admin = adminClient();
      // set timeout_at to the past
      await admin.from('transactions').update({
        'timeout_at': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      }).eq('id', txId);

      final client = await signInAsBiruk();
      // Call auto-cancel RPC
      await client.rpc('auto_cancel_expired_transactions');

      final tx = await admin.from('transactions').select('status').eq('id', txId).single();
      expect(tx['status'], 'cancelled');
      await client.auth.signOut();
    });
  });
}
