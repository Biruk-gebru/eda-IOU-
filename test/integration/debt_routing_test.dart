import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_config.dart';

// User IDs ordered lexicographically for net_balances row layout:
// Meron(11) < Bisrat(1a) < Biruk(42) < Abel(a6) < Kaleab(db)
//
// Net balance sign convention:
//   user_a < user_b, net_amount > 0 → user_a owes user_b
//   user_a < user_b, net_amount < 0 → user_b owes user_a
//
// Existing test data (restored after each test):
//   Biruk/Abel  net=-50  → Abel owes Biruk 50
//   Meron/Biruk net=-100 → Biruk owes Meron 100
//   Bisrat/Biruk net=200 → Bisrat owes Biruk 200
//   Biruk/Kaleab net=300 → Biruk owes Kaleab 300

void main() {
  group('Net balances — read', () {
    test('existing balances have correct signs', () async {
      final client = await signInAsBiruk();

      final rows = await client
          .from('net_balances')
          .select('user_a, user_b, net_amount')
          .or('user_a.eq.$kBirukId,user_b.eq.$kBirukId');

      final map = {
        for (final r in rows as List)
          '${r['user_a']}_${r['user_b']}': (r['net_amount'] as num).toDouble()
      };

      // Abel owes Biruk 50 → user_a=Biruk, user_b=Abel, net=-50
      expect(map['${kBirukId}_$kAbelId'], -50.0);
      // Biruk owes Meron 100 → user_a=Meron, user_b=Biruk, net=-100
      expect(map['${kMeronId}_$kBirukId'], -100.0);
      // Bisrat owes Biruk 200 → user_a=Bisrat, user_b=Biruk, net=200
      expect(map['${kBisratId}_$kBirukId'], 200.0);
      // Biruk owes Kaleab 300 → user_a=Biruk, user_b=Kaleab, net=300
      expect(map['${kBirukId}_$kKaleabId'], 300.0);

      await client.auth.signOut();
    });

    test('getGroupNetBalances Office Crew returns only Office Crew member edges', () async {
      final client = await signInAsBiruk();

      // Replicate getGroupNetBalances logic:
      // 1. get member IDs for the group
      final memberRows = await client
          .from('group_members')
          .select('user_id')
          .eq('group_id', kGroupOfficeCrewId)
          .eq('status', 'active');
      final memberIds = (memberRows as List).map((r) => r['user_id'] as String).toList();
      expect(memberIds, containsAll([kBirukId, kAbelId, kMeronId]));

      // 2. get balances where both parties are group members
      final balances = await client
          .from('net_balances')
          .select('user_a, user_b, net_amount')
          .inFilter('user_a', memberIds)
          .inFilter('user_b', memberIds)
          .neq('net_amount', 0);

      // Office Crew: Biruk/Abel (-50) and Meron/Biruk (-100)
      expect((balances as List).length, 2);
      final keys = balances.map((r) => '${r['user_a']}_${r['user_b']}').toSet();
      expect(keys, containsAll(['${kBirukId}_$kAbelId', '${kMeronId}_$kBirukId']));

      await client.auth.signOut();
    });
  });

  group('Debt routing — apply_debt_routing_chain RPC', () {
    late List<Map<String, dynamic>> snapshot;

    setUp(() async {
      snapshot = await snapshotNetBalances(adminClient());
    });

    tearDown(() async {
      await restoreNetBalances(adminClient(), snapshot);
    });

    test('1-hop route: Abel→Biruk→Meron, amount=50 — correct balance changes', () async {
      final client = await signInAsBiruk();

      // Chain: Abel→Biruk (Abel owes Biruk 50) then Biruk→Meron (Biruk owes Meron 100)
      // Route 50: Abel's debt to Biruk clears; Biruk's debt to Meron reduces to 50
      await client.rpc('apply_debt_routing_chain', params: {
        'p_edges': [
          {'debtor_id': kAbelId,  'creditor_id': kBirukId},
          {'debtor_id': kBirukId, 'creditor_id': kMeronId},
        ],
        'p_amount': 50.0,
      });

      final admin = adminClient();

      // Biruk/Abel row: net was -50, after routing Abel's debt clears → row deleted
      final abelRow = await admin
          .from('net_balances')
          .select()
          .eq('user_a', kBirukId)
          .eq('user_b', kAbelId);
      expect((abelRow as List).isEmpty, isTrue, reason: 'Abel–Biruk balance should be cleared');

      // Meron/Biruk row: net was -100, after routing reduces by 50 → net=-50
      final meronRow = await admin
          .from('net_balances')
          .select('net_amount')
          .eq('user_a', kMeronId)
          .eq('user_b', kBirukId)
          .single();
      expect((meronRow['net_amount'] as num).toDouble(), -50.0,
          reason: 'Biruk now owes Meron only 50');

      await client.auth.signOut();
    });

    test('routing by amount less than edge — partial reduction, no deletion', () async {
      final client = await signInAsBiruk();

      // Route only 20 (Abel owes Biruk 50, so 30 remains)
      await client.rpc('apply_debt_routing_chain', params: {
        'p_edges': [
          {'debtor_id': kAbelId,  'creditor_id': kBirukId},
          {'debtor_id': kBirukId, 'creditor_id': kMeronId},
        ],
        'p_amount': 20.0,
      });

      final admin = adminClient();

      final abelRow = await admin
          .from('net_balances')
          .select('net_amount')
          .eq('user_a', kBirukId)
          .eq('user_b', kAbelId)
          .single();
      // net was -50 (Abel owes Biruk 50). Routing 20 from Abel→Biruk:
      // Abel (debtor) > Biruk (creditor) → ELSE branch → net += 20 → net = -30
      expect((abelRow['net_amount'] as num).toDouble(), -30.0,
          reason: 'Abel still owes Biruk 30');

      await client.auth.signOut();
    });

    test('1-hop Addis Trip: Bisrat→Biruk→Kaleab, amount=200 — Bisrat clears, Biruk reduces', () async {
      final client = await signInAsBiruk();

      await client.rpc('apply_debt_routing_chain', params: {
        'p_edges': [
          {'debtor_id': kBisratId, 'creditor_id': kBirukId},
          {'debtor_id': kBirukId,  'creditor_id': kKaleabId},
        ],
        'p_amount': 200.0,
      });

      final admin = adminClient();

      // Bisrat/Biruk net was 200 → reduces by 200 → 0 → row deleted
      final bisratRow = await admin
          .from('net_balances')
          .select()
          .eq('user_a', kBisratId)
          .eq('user_b', kBirukId);
      expect((bisratRow as List).isEmpty, isTrue, reason: 'Bisrat debt to Biruk fully cleared');

      // Biruk/Kaleab net was 300 → reduces by 200 → 100
      final kaleabRow = await admin
          .from('net_balances')
          .select('net_amount')
          .eq('user_a', kBirukId)
          .eq('user_b', kKaleabId)
          .single();
      expect((kaleabRow['net_amount'] as num).toDouble(), 100.0);

      await client.auth.signOut();
    });

    test('RPC with empty chain is a no-op — net_balances unchanged', () async {
      final client = await signInAsBiruk();
      final admin = adminClient();
      final before = await snapshotNetBalances(admin);

      await client.rpc('apply_debt_routing_chain', params: {
        'p_edges': <Map<String, dynamic>>[],
        'p_amount': 50.0,
      });

      final after = await admin.from('net_balances').select();
      expect((after as List).length, before.length,
          reason: 'Empty chain should not change any rows');
      await client.auth.signOut();
    });

    test('unauthenticated call to apply_debt_routing_chain is rejected', () async {
      final anonClient = SupabaseClient(kSupabaseUrl, kAnonKey);
      // Not signed in — should fail RLS/auth check
      expect(
        () => anonClient.rpc('apply_debt_routing_chain', params: {
          'p_edges': [
            {'debtor_id': kAbelId, 'creditor_id': kBirukId},
          ],
          'p_amount': 10.0,
        }),
        throwsA(anything),
      );
    });
  });
}
