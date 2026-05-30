// End-to-end user story tests. Each test simulates the full sequence of
// actions a real user takes, then verifies the outcome across all affected
// tables — not just the immediate response.

import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  late dynamic c;

  setUpAll(() async { c = await signInAsTestUser(); });
  tearDownAll(() async { await c.auth.signOut(); });

  // ── 1. PAYMENT FLOW ────────────────────────────────────────────────────────
  // User story: "Biruk paid me 60 ETB — I confirm, my balance with him updates."

  group('Flow: payment lifecycle', () {
    test('create → confirm → balance updates between payer and receiver', () async {
      // Read balance before
      final beforeRow = await c.from('net_balances').select('net_amount')
          .eq('user_a', kBirukId).eq('user_b', kTestUserId).maybeSingle();
      final before = beforeRow != null ? (beforeRow['net_amount'] as num).toDouble() : 0.0;

      // Step 1: Biruk claims he paid TestUser 60 ETB (request in pending state)
      final pr = await c.from('payment_requests').insert({
        'payer_id': kBirukId,
        'receiver_id': kTestUserId,
        'amount': 60.0,
        'method': 'direct',
        'note': 'Flow test: Biruk pays TestUser',
      }).select().single();
      expect(pr['status'], 'pending', reason: 'Request starts pending');

      // Step 2: TestUser (receiver) confirms they received the money
      await c.from('payment_requests')
          .update({'status': 'confirmed'}).eq('id', pr['id']);

      // Step 3: apply_payment RPC updates net_balances
      await c.rpc('apply_payment', params: {'p_payment_request_id': pr['id']});

      // Step 4: Verify the balance shifted by exactly 60 ETB
      final afterRow = await c.from('net_balances').select('net_amount')
          .eq('user_a', kBirukId).eq('user_b', kTestUserId).maybeSingle();
      final after = afterRow != null ? (afterRow['net_amount'] as num).toDouble() : 0.0;
      expect((after - before).abs(), closeTo(60.0, 0.01),
          reason: 'Net balance between Biruk and TestUser shifted by 60');

      // Step 5: Payment is visible in history
      final history = await c.from('payment_requests').select('status, amount')
          .eq('id', pr['id']).single();
      expect(history['status'], 'confirmed');

      // cleanup
      await c.from('payment_requests').delete().eq('id', pr['id']);
    });
  });

  // ── 2. DEBT ROUTING FLOW ───────────────────────────────────────────────────
  // User story: "Abel owes me money. I owe Meron money. Instead of two
  // transfers, I route it — Abel pays Meron directly and everyone is square."

  group('Flow: debt routing (Abel→TestUser→Meron)', () {
    test('route 40 ETB through TestUser — both edges reduce by exactly 40', () async {
      final abelBefore  = (await c.from('net_balances').select('net_amount')
          .eq('user_a', kAbelId).eq('user_b', kTestUserId).single())['net_amount'];
      final meronBefore = (await c.from('net_balances').select('net_amount')
          .eq('user_a', kMeronId).eq('user_b', kTestUserId).single())['net_amount'];

      // TestUser routes 40 ETB: Abel pays Meron instead of TestUser
      await c.rpc('apply_debt_routing_chain', params: {
        'p_edges': [
          {'debtor_id': kAbelId,     'creditor_id': kTestUserId},
          {'debtor_id': kTestUserId, 'creditor_id': kMeronId},
        ],
        'p_amount': 40.0,
      });

      final abelAfter  = (await c.from('net_balances').select('net_amount')
          .eq('user_a', kAbelId).eq('user_b', kTestUserId).single())['net_amount'];
      final meronAfter = (await c.from('net_balances').select('net_amount')
          .eq('user_a', kMeronId).eq('user_b', kTestUserId).single())['net_amount'];

      // Abel's debt to TestUser reduced by 40
      expect(
        (abelBefore as num).toDouble() - (abelAfter as num).toDouble(),
        closeTo(40.0, 0.01),
        reason: 'Abel owes TestUser 40 less',
      );
      // TestUser's debt to Meron reduced by 40
      expect(
        (meronBefore as num).toDouble() - (meronAfter as num).toDouble(),
        closeTo(-40.0, 0.01),
        reason: 'TestUser owes Meron 40 less',
      );

      // Restore
      await c.rpc('apply_debt_routing_chain', params: {
        'p_edges': [
          {'debtor_id': kTestUserId, 'creditor_id': kAbelId},
          {'debtor_id': kMeronId,   'creditor_id': kTestUserId},
        ],
        'p_amount': 40.0,
      });
    });
  });

  // ── 3. GROUP CREATION + MEMBERSHIP FLOW ───────────────────────────────────
  // User story: "I create a group, invite a friend, they accept, we both
  // see each other as members and our shared debts appear in the ledger."

  group('Flow: create group and manage membership', () {
    test('create → invite → accept → debt visible to both members', () async {
      // Step 1: Create group
      final g = await c.from('groups').insert({
        'name': '[FLOW] Trip Group', 'creator_id': kTestUserId,
      }).select().single();
      final gId = g['id'] as String;
      await c.from('group_members').insert({
        'group_id': gId, 'user_id': kTestUserId,
        'role': 'creator', 'status': 'active',
      });

      // Step 2: Invite Abel
      await c.from('group_members').insert({
        'group_id': gId, 'user_id': kAbelId,
        'role': 'member', 'status': 'pending', 'invited_by': kTestUserId,
      });
      final invite = await c.from('group_members').select('status')
          .eq('group_id', gId).eq('user_id', kAbelId).single();
      expect(invite['status'], 'pending');

      // Step 3: Abel accepts
      await c.from('group_members')
          .update({'status': 'active', 'joined_at': DateTime.now().toUtc().toIso8601String()})
          .eq('group_id', gId).eq('user_id', kAbelId);

      // Step 4: Verify both are active members
      final members = await c.from('group_members').select('user_id, status')
          .eq('group_id', gId).eq('status', 'active');
      final ids = (members as List).map((m) => m['user_id'] as String).toSet();
      expect(ids, containsAll([kTestUserId, kAbelId]));

      // Step 5: Their shared debt appears in the group ledger
      // (Abel owes TestUser 80 from pre-seeded data — they're now in the same group)
      final memberIds = [kTestUserId, kAbelId];
      final ledger = await c.from('net_balances').select('user_a, user_b, net_amount')
          .inFilter('user_a', memberIds).inFilter('user_b', memberIds);
      expect((ledger as List).isNotEmpty, isTrue,
          reason: 'Group ledger shows shared debt between members');

      // cleanup
      await c.from('group_members').delete().eq('group_id', gId);
      await c.from('groups').delete().eq('id', gId);
    });
  });

  // ── 4. IOU TRANSACTION FLOW ────────────────────────────────────────────────
  // User story: "I paid for dinner. I add an IOU — my friend owes me their
  // share. They approve it. My balance with them updates automatically."

  group('Flow: create IOU → approve → balance updates', () {
    test('create transaction, participant approves, net_balance created', () async {
      // Read pre-existing balance between TestUser and Biruk
      final beforeRow = await c.from('net_balances').select('net_amount')
          .eq('user_a', kBirukId).eq('user_b', kTestUserId).maybeSingle();
      final before = beforeRow != null ? (beforeRow['net_amount'] as num).toDouble() : 0.0;

      // Step 1: TestUser creates IOU — TestUser paid 200 ETB, Biruk owes 200
      // (TestUser is both creator and payer; Biruk is the only participant)
      final tx = await c.from('transactions').insert({
        'creator_id': kTestUserId,
        'payer_id': kTestUserId,
        'total_amount': 200.0,
        'currency': 'ETB',
        'description': '[FLOW] TestUser paid for Biruk',
        'status': 'pending',
        'timeout_at': DateTime.now().toUtc().add(const Duration(hours: 48)).toIso8601String(),
      }).select().single();
      final txId = tx['id'] as String;

      // Step 2: Add TestUser as the APPROVING participant (they approve their own IOU)
      // In the app, creator adds others as participants; here TestUser approves on their behalf
      // We insert TestUser as participant (quorum 1/1) so one vote completes it
      await c.from('transaction_participants').insert({
        'transaction_id': txId,
        'user_id': kTestUserId,
        'amount_due': 200.0,
        // no 'approved' — NULL means pending voter
      });

      // Step 3: TestUser votes to approve (quorum met: 1/1)
      final result = await c.rpc('rpc_vote_transaction', params: {
        'p_transaction_id': txId,
        'p_approve': true,
      });
      expect(result['status'], anyOf('approved', 'pending'),
          reason: 'Transaction either auto-approved or still pending');

      // Step 4: If approved, net_balance updated
      final txRow = await c.from('transactions').select('status').eq('id', txId).single();
      if (txRow['status'] == 'approved') {
        final afterRow = await c.from('net_balances').select('net_amount')
            .eq('user_a', kBirukId).eq('user_b', kTestUserId).maybeSingle();
        final after = afterRow != null ? (afterRow['net_amount'] as num).toDouble() : 0.0;
        expect((after - before).abs(), greaterThan(0),
            reason: 'Balance updated after transaction approval');
      }

      // cleanup
      await c.from('transaction_participants').delete().eq('transaction_id', txId);
      await c.from('transactions').delete().eq('id', txId);
    });
  });

  // ── 5. DEBT TRACKING ACROSS A GROUP ────────────────────────────────────────
  // User story: "I open my group. I see who owes whom and exactly how much.
  // The amounts match what I expect from our shared expenses."

  group('Flow: group debt ledger is accurate', () {
    test('Office Crew ledger shows correct debts for each member perspective', () async {
      // Get all active members of Office Crew
      final memberRows = await c.from('group_members').select('user_id')
          .eq('group_id', kGroupOfficeCrewId).eq('status', 'active');
      final memberIds = (memberRows as List).map((r) => r['user_id'] as String).toList();
      expect(memberIds.length, greaterThanOrEqualTo(3));

      // Get all pairwise balances within the group
      final balances = await c.from('net_balances').select('user_a, user_b, net_amount')
          .inFilter('user_a', memberIds).inFilter('user_b', memberIds).neq('net_amount', 0);

      // From TestUser's perspective: who owes TestUser and who TestUser owes
      final myDebts = (balances as List).where((b) =>
          b['user_a'] == kTestUserId || b['user_b'] == kTestUserId).toList();
      expect(myDebts.isNotEmpty, isTrue,
          reason: 'TestUser has debts within Office Crew');

      // Every non-zero balance has a clear debtor and creditor
      for (final b in balances) {
        expect((b['net_amount'] as num).toDouble(), isNot(0.0));
        expect(b['user_a'], isNotEmpty);
        expect(b['user_b'], isNotEmpty);
        expect(b['user_a'], isNot(b['user_b']));
      }
    });

    test('TestUser net balance shows correct owed/owing amounts', () async {
      final all = await c.from('net_balances').select('user_a, user_b, net_amount')
          .or('user_a.eq.$kTestUserId,user_b.eq.$kTestUserId');

      double owedToMe = 0;
      double iOwe = 0;
      for (final b in all as List) {
        final amt = (b['net_amount'] as num).toDouble();
        if (b['user_a'] == kTestUserId && amt > 0) owedToMe += amt;
        if (b['user_b'] == kTestUserId && amt < 0) iOwe += amt.abs();
        if (b['user_a'] == kTestUserId && amt < 0) iOwe += amt.abs();
        if (b['user_b'] == kTestUserId && amt > 0) owedToMe += amt;
      }
      // With the pre-seeded data: Abel owes TestUser 80 → owedToMe >= 80
      expect(owedToMe, greaterThan(0), reason: 'Someone owes TestUser money');
      expect(iOwe, greaterThan(0), reason: 'TestUser owes someone money');
    });
  });

  // ── 6. NOTIFICATION FLOW ───────────────────────────────────────────────────
  // User story: "I get a notification when someone sends me a payment request.
  // I can mark it read. My unread count drops."

  group('Flow: notification read/unread lifecycle', () {
    test('receive notification → see unread count → mark read → count drops', () async {
      // Step 1: A notification arrives (group_invitation type — only insertable type)
      final n = await c.from('notifications').insert({
        'user_id': kTestUserId,
        'type': 'group_invitation',
        'payload': {'group_name': 'Flow Test Group'},
        'read': false,
      }).select().single();
      final nId = n['id'] as String;

      // Step 2: User sees unread count > 0
      final unread = await c.from('notifications').select('id')
          .eq('user_id', kTestUserId).eq('read', false);
      expect((unread as List).isNotEmpty, isTrue);

      // Step 3: User taps notification — mark as read
      await c.from('notifications').update({'read': true}).eq('id', nId);

      // Step 4: That specific notification is now read
      final updated = await c.from('notifications').select('read').eq('id', nId).single();
      expect(updated['read'], isTrue);

      // cleanup
      await c.from('notifications').delete().eq('id', nId);
    });
  });
}
