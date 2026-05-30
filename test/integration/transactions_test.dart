import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  late dynamic client;
  late String txId;

  setUpAll(() async { client = await signInAsTestUser(); });
  tearDownAll(() async { await client.auth.signOut(); });

  setUp(() async {
    final tx = await client.from('transactions').insert({
      'creator_id': kTestUserId,
      'payer_id': kBirukId,
      'total_amount': 300.0,
      'currency': 'ETB',
      'description': '[TEST] Dinner',
      'status': 'pending',
      'timeout_at': DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
    }).select().single();
    txId = tx['id'] as String;

    // Do NOT set approved — RPC checks `approved IS NULL` for pending voters
    await client.from('transaction_participants').insert({
      'transaction_id': txId,
      'user_id': kTestUserId,
      'amount_due': 150.0,
    });
  });

  tearDown(() async {
    await client.from('transaction_participants').delete().eq('transaction_id', txId);
    await client.from('transactions').delete().eq('id', txId);
  });

  test('created transaction has correct fields', () async {
    final tx = await client.from('transactions').select().eq('id', txId).single();
    expect(tx['description'], '[TEST] Dinner');
    expect((tx['total_amount'] as num).toDouble(), 300.0);
    expect(tx['status'], 'pending');
  });

  test('participant list is correct', () async {
    final parts = await client.from('transaction_participants').select()
        .eq('transaction_id', txId);
    expect((parts as List).length, 1);
    expect(parts.first['user_id'], kTestUserId);
    expect((parts.first['amount_due'] as num).toDouble(), 150.0);
    // approved has no DEFAULT — omitting it on insert gives NULL, which is what
    // rpc_vote_transaction checks for (`approved IS NULL` = "pending voter")
    expect(parts.first['approved'], isNull);
  });

  test('TestUser can vote via rpc_vote_transaction', () async {
    await client.rpc('rpc_vote_transaction', params: {
      'p_transaction_id': txId,
      'p_approve': true,
    });
    final part = await client.from('transaction_participants').select('approved')
        .eq('transaction_id', txId).eq('user_id', kTestUserId).single();
    expect(part['approved'], isTrue);
  });

  test('transaction appears in get_my_transaction_ids', () async {
    final ids = (await client.rpc('get_my_transaction_ids') as List).cast<String>();
    expect(ids, contains(txId));
  });

  test('auto_cancel_expired_transactions cancels timed-out tx', () async {
    // Use UTC — without toUtc() Dart omits timezone offset and Postgres reads it as UTC,
    // making a "past" local time appear as a future UTC time.
    await client.from('transactions')
        .update({'timeout_at': DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String()})
        .eq('id', txId);
    await client.rpc('auto_cancel_expired_transactions');
    final tx = await client.from('transactions').select('status').eq('id', txId).single();
    expect(tx['status'], 'cancelled');
  });
}
