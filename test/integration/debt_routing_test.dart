// Net balance layout for TestUser (pre-seeded via SQL):
//   Abel(a6) < TestUser(ff): user_a=Abel, user_b=TestUser, net=80  → Abel owes TestUser 80
//   Meron(11) < TestUser(ff): user_a=Meron, user_b=TestUser, net=-120 → TestUser owes Meron 120
//
// Each routing test reads the CURRENT balance before acting, checks the DELTA,
// then restores inline — so tests survive state drift between runs.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_config.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Future<double?> _abelBal(dynamic c) async {
  final row = await c.from('net_balances').select('net_amount')
      .eq('user_a', kAbelId).eq('user_b', kTestUserId).maybeSingle();
  return row != null ? (row['net_amount'] as num).toDouble() : null;
}

Future<double?> _meronBal(dynamic c) async {
  final row = await c.from('net_balances').select('net_amount')
      .eq('user_a', kMeronId).eq('user_b', kTestUserId).maybeSingle();
  return row != null ? (row['net_amount'] as num).toDouble() : null;
}

Future<void> _route(dynamic c, double amount) async {
  await c.rpc('apply_debt_routing_chain', params: {
    'p_edges': [
      {'debtor_id': kAbelId,     'creditor_id': kTestUserId},
      {'debtor_id': kTestUserId, 'creditor_id': kMeronId},
    ],
    'p_amount': amount,
  });
}

Future<void> _unroute(dynamic c, double amount) async {
  await c.rpc('apply_debt_routing_chain', params: {
    'p_edges': [
      {'debtor_id': kTestUserId, 'creditor_id': kAbelId},
      {'debtor_id': kMeronId,   'creditor_id': kTestUserId},
    ],
    'p_amount': amount,
  });
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late dynamic client;

  setUpAll(() async { client = await signInAsTestUser(); });
  tearDownAll(() async { await client.auth.signOut(); });

  group('Net balances — read', () {
    test('TestUser edges exist with correct signs', () async {
      final rows = await client.from('net_balances').select('user_a, user_b, net_amount')
          .or('user_a.eq.$kTestUserId,user_b.eq.$kTestUserId');
      final map = { for (final r in rows as List)
        '${r['user_a']}_${r['user_b']}': (r['net_amount'] as num).toDouble() };

      // Abel owes TestUser → net_amount > 0 (user_a=Abel, user_b=TestUser)
      expect(map['${kAbelId}_$kTestUserId'], greaterThan(0),
          reason: 'Abel owes TestUser a positive amount');
      // TestUser owes Meron → net_amount < 0 (user_a=Meron, user_b=TestUser)
      expect(map['${kMeronId}_$kTestUserId'], lessThan(0),
          reason: 'TestUser owes Meron (negative for user_b)');
    });

    test('Office Crew balances include TestUser edges', () async {
      final memberRows = await client.from('group_members').select('user_id')
          .eq('group_id', kGroupOfficeCrewId).eq('status', 'active');
      final ids = (memberRows as List).map((r) => r['user_id'] as String).toList();
      final balances = await client.from('net_balances').select('user_a, user_b')
          .inFilter('user_a', ids).inFilter('user_b', ids).neq('net_amount', 0);
      final keys = (balances as List).map((r) => '${r['user_a']}_${r['user_b']}').toSet();
      expect(keys.any((k) => k.contains(kTestUserId)), isTrue);
    });

    test('unauthenticated client sees zero rows', () async {
      final anon = SupabaseClient(kSupabaseUrl, kAnonKey);
      final rows = await anon.from('net_balances').select().eq('user_b', kTestUserId);
      expect((rows as List).isEmpty, isTrue);
    });
  });

  group('apply_debt_routing_chain', () {
    // Each test is self-contained: reads balance before, routes, checks delta, restores.

    test('1-hop route=10: Abel→TestUser→Meron — both edges reduce by 10', () async {
      final abelBefore  = await _abelBal(client)  ?? 80.0;
      final meronBefore = await _meronBal(client) ?? -120.0;

      await _route(client, 10.0);

      final abelAfter  = await _abelBal(client)  ?? 0.0;
      final meronAfter = await _meronBal(client) ?? 0.0;

      expect(abelBefore  - abelAfter,  closeTo(10.0, 0.01), reason: 'Abel edge reduced by 10');
      expect(meronBefore - meronAfter, closeTo(-10.0, 0.01), reason: 'Meron edge reduced by 10');

      await _unroute(client, 10.0); // restore
    });

    test('empty chain is a no-op — balances unchanged', () async {
      final abelBefore = await _abelBal(client) ?? 80.0;

      await client.rpc('apply_debt_routing_chain', params: {
        'p_edges': <Map<String, dynamic>>[], 'p_amount': 50.0,
      });

      final abelAfter = await _abelBal(client) ?? 80.0;
      expect(abelAfter, closeTo(abelBefore, 0.01));
    });

    test('routing down to last 1 ETB leaves row intact with reduced amount', () async {
      // Route (abelBefore - 1) so net reaches 1 but does NOT delete the row.
      // This tests the reduction path without deleting state needed by later tests.
      final abelBefore = await _abelBal(client) ?? 80.0;
      expect(abelBefore, greaterThan(1), reason: 'Pre-condition: Abel owes TestUser > 1');
      final routeAmt = abelBefore - 1;

      await _route(client, routeAmt);

      final abelAfter = await _abelBal(client);
      expect(abelAfter, isNotNull, reason: 'Row still exists (net_amount = 1, not 0)');
      expect(abelAfter, closeTo(1.0, 0.01));

      await _unroute(client, routeAmt); // restore
    });

    test('partial route leaves both edges intact', () async {
      final abelBefore = await _abelBal(client) ?? 80.0;
      final routeAmt = 5.0; // small amount guaranteed not to delete the row

      await _route(client, routeAmt);

      final abelAfter = await _abelBal(client);
      expect(abelAfter, isNotNull, reason: 'Row still exists after partial route');
      expect(abelBefore - abelAfter!, closeTo(routeAmt, 0.01));

      await _unroute(client, routeAmt); // restore
    });
  });
}
