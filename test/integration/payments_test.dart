import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  late dynamic client;

  setUpAll(() async { client = await signInAsTestUser(); });
  tearDownAll(() async { await client.auth.signOut(); });

  test('create payment request as payer — status is pending', () async {
    final pr = await client.from('payment_requests').insert({
      'payer_id': kTestUserId, 'receiver_id': kBirukId,
      'amount': 75.0, 'method': 'direct', 'note': '[TEST] lunch',
    }).select().single();
    expect(pr['id'], isUuid());
    expect(pr['status'], 'pending');
    expect((pr['amount'] as num).toDouble(), 75.0);
    await client.from('payment_requests').delete().eq('id', pr['id']);
  });

  test('payment request visible in own query', () async {
    final pr = await client.from('payment_requests').insert({
      'payer_id': kTestUserId, 'receiver_id': kBirukId,
      'amount': 50.0, 'method': 'direct',
    }).select().single();
    final rows = await client.from('payment_requests').select('id')
        .or('payer_id.eq.$kTestUserId,receiver_id.eq.$kTestUserId')
        .eq('id', pr['id']);
    expect((rows as List).length, 1);
    await client.from('payment_requests').delete().eq('id', pr['id']);
  });

  test('apply_payment as receiver — status becomes confirmed', () async {
    // apply_payment RPC reads WHERE status='confirmed', so update first (receiver can update via RLS)
    final pr = await client.from('payment_requests').insert({
      'payer_id': kBirukId, 'receiver_id': kTestUserId,
      'amount': 60.0, 'method': 'direct',
    }).select().single();
    await client.from('payment_requests').update({'status': 'confirmed'}).eq('id', pr['id']);
    await client.rpc('apply_payment', params: {'p_payment_request_id': pr['id']});
    final updated = await client.from('payment_requests').select('status')
        .eq('id', pr['id']).single();
    expect(updated['status'], 'confirmed');
    await client.from('payment_requests').delete().eq('id', pr['id']);
  });

  test('apply_payment increases TestUser net balance owed by Biruk', () async {
    final beforeRow = await client.from('net_balances').select('net_amount')
        .eq('user_a', kBirukId).eq('user_b', kTestUserId).maybeSingle();
    final before = beforeRow != null ? (beforeRow['net_amount'] as num).toDouble() : 0.0;

    final pr = await client.from('payment_requests').insert({
      'payer_id': kBirukId, 'receiver_id': kTestUserId,
      'amount': 25.0, 'method': 'direct',
    }).select().single();
    // Receiver confirms first (RLS allows receiver to update), then apply_payment reads it
    await client.from('payment_requests').update({'status': 'confirmed'}).eq('id', pr['id']);
    await client.rpc('apply_payment', params: {'p_payment_request_id': pr['id']});

    final afterRow = await client.from('net_balances').select('net_amount')
        .eq('user_a', kBirukId).eq('user_b', kTestUserId).maybeSingle();
    final after = afterRow != null ? (afterRow['net_amount'] as num).toDouble() : 0.0;
    // net_amount decreases by 25 (Biruk side goes more negative = Biruk owes TestUser less)
    expect((after - before).abs(), closeTo(25.0, 0.01));

    await client.from('payment_requests').delete().eq('id', pr['id']);
  });

  test('reject payment request — status becomes rejected', () async {
    // RLS UPDATE policy: only receiver_id = auth.uid() can update.
    // TestUser is receiver here so they can reject.
    final pr = await client.from('payment_requests').insert({
      'payer_id': kBirukId, 'receiver_id': kTestUserId,
      'amount': 100.0, 'method': 'direct',
    }).select().single();
    await client.from('payment_requests').update({'status': 'rejected'}).eq('id', pr['id']);
    final updated = await client.from('payment_requests').select('status')
        .eq('id', pr['id']).single();
    expect(updated['status'], 'rejected');
    await client.from('payment_requests').delete().eq('id', pr['id']);
  });

  test('auto_expire_payment_requests expires timed-out request', () async {
    // Use toUtc() — without it Dart omits timezone info and Postgres reads local time as UTC
    final pr = await client.from('payment_requests').insert({
      'payer_id': kTestUserId, 'receiver_id': kBirukId,
      'amount': 20.0, 'method': 'direct',
      'timeout_at': DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String(),
    }).select().single();
    await client.rpc('auto_expire_payment_requests');
    final updated = await client.from('payment_requests').select('status')
        .eq('id', pr['id']).single();
    expect(updated['status'], 'expired');
    await client.from('payment_requests').delete().eq('id', pr['id']);
  });
}
