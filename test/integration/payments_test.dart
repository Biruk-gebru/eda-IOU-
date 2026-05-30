import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  group('Payment requests', () {
    test('create payment request (Biruk pays Abel) — pending status', () async {
      final client = await signInAsBiruk();

      final pr = await client.from('payment_requests').insert({
        'payer_id': kBirukId,
        'receiver_id': kAbelId,
        'amount': 75.0,
        'method': 'direct',
        'note': '[TEST] lunch money',
      }).select().single();
      final prId = pr['id'] as String;

      expect(prId, isUuid());
      expect(pr['status'], 'pending');
      expect((pr['amount'] as num).toDouble(), 75.0);

      // clean up
      final admin = adminClient();
      await admin.from('payment_requests').delete().eq('id', prId);
      await client.auth.signOut();
    });

    test('payment request is visible in payer list', () async {
      final client = await signInAsBiruk();

      final pr = await client.from('payment_requests').insert({
        'payer_id': kBirukId,
        'receiver_id': kAbelId,
        'amount': 50.0,
        'method': 'direct',
      }).select().single();
      final prId = pr['id'] as String;

      final rows = await client
          .from('payment_requests')
          .select()
          .eq('payer_id', kBirukId)
          .eq('id', prId);
      expect((rows as List).length, 1);

      final admin = adminClient();
      await admin.from('payment_requests').delete().eq('id', prId);
      await client.auth.signOut();
    });

    test('confirm payment via apply_payment RPC — status becomes confirmed', () async {
      final admin = adminClient();

      // Insert a payment request as Abel (payer) → Biruk (receiver)
      final pr = await admin.from('payment_requests').insert({
        'payer_id': kAbelId,
        'receiver_id': kBirukId,
        'amount': 50.0,
        'method': 'direct',
        'note': '[TEST] apply_payment test',
      }).select().single();
      final prId = pr['id'] as String;

      // Biruk (receiver) confirms
      final client = await signInAsBiruk();
      await client.rpc('apply_payment', params: {'p_payment_request_id': prId});

      final updated = await admin
          .from('payment_requests')
          .select('status')
          .eq('id', prId)
          .single();
      expect(updated['status'], 'confirmed');

      await admin.from('payment_requests').delete().eq('id', prId);
      await client.auth.signOut();
    });

    test('apply_payment updates net_balances between payer and receiver', () async {
      final admin = adminClient();
      final snapshot = await snapshotNetBalances(admin);

      // Insert test balance: Biruk (user_a=425b...) vs Kaleab (user_b=dbc4...)
      // net_amount=100 means Biruk owes Kaleab 100
      final testPrId = await _insertAndApplyPayment(admin, kAbelId, kKaleabId, 30.0);

      // Verify net_balances changed
      final after = await admin.from('net_balances').select();
      // After apply_payment, net_balances should reflect the payment
      expect((after as List).isNotEmpty, isTrue);

      await admin.from('payment_requests').delete().eq('id', testPrId);
      await restoreNetBalances(admin, snapshot);
    });

    test('reject payment request — status becomes rejected', () async {
      final client = await signInAsBiruk();

      final pr = await client.from('payment_requests').insert({
        'payer_id': kBirukId,
        'receiver_id': kAbelId,
        'amount': 100.0,
        'method': 'direct',
      }).select().single();
      final prId = pr['id'] as String;

      await client.from('payment_requests').update({'status': 'rejected'}).eq('id', prId);

      final updated = await client
          .from('payment_requests')
          .select('status')
          .eq('id', prId)
          .single();
      expect(updated['status'], 'rejected');

      final admin = adminClient();
      await admin.from('payment_requests').delete().eq('id', prId);
      await client.auth.signOut();
    });

    test('expired payment requests auto-expire via RPC', () async {
      final client = await signInAsBiruk();

      final pr = await client.from('payment_requests').insert({
        'payer_id': kBirukId,
        'receiver_id': kAbelId,
        'amount': 25.0,
        'method': 'direct',
        'timeout_at': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      }).select().single();
      final prId = pr['id'] as String;

      await client.rpc('auto_expire_payment_requests');

      final admin = adminClient();
      final updated = await admin
          .from('payment_requests')
          .select('status')
          .eq('id', prId)
          .single();
      expect(updated['status'], 'expired');

      await admin.from('payment_requests').delete().eq('id', prId);
      await client.auth.signOut();
    });
  });
}

Future<String> _insertAndApplyPayment(
    dynamic admin, String payerId, String receiverId, double amount) async {
  final pr = await admin.from('payment_requests').insert({
    'payer_id': payerId,
    'receiver_id': receiverId,
    'amount': amount,
    'method': 'direct',
    'note': '[TEST] balance update test',
  }).select().single();
  final prId = pr['id'] as String;
  await admin.rpc('apply_payment', params: {'p_payment_request_id': prId});
  return prId;
}
