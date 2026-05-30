import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  late dynamic client;

  setUpAll(() async { client = await signInAsTestUser(); });
  tearDownAll(() async { await client.auth.signOut(); });

  test('test user profile exists with non-empty display_name', () async {
    final row = await client.from('profiles').select('id, display_name')
        .eq('id', kTestUserId).single();
    expect(row['id'], kTestUserId);
    expect(row['display_name'], isNotEmpty);
  });

  test('all 5 mock user profiles are readable', () async {
    final rows = await client.from('profiles').select('id')
        .inFilter('id', [kBirukId, kAbelId, kMeronId, kBisratId, kKaleabId]);
    expect((rows as List).length, 5);
  });

  test('update and restore display_name', () async {
    final original = (await client.from('profiles').select('display_name')
        .eq('id', kTestUserId).single())['display_name'] as String;

    await client.from('profiles').update({'display_name': 'Updated'})
        .eq('id', kTestUserId);
    final updated = (await client.from('profiles').select('display_name')
        .eq('id', kTestUserId).single())['display_name'] as String;
    expect(updated, 'Updated');

    await client.from('profiles').update({'display_name': original})
        .eq('id', kTestUserId);
  });

  test('ilike search on display_name returns results', () async {
    final rows = await client.from('profiles').select('id')
        .ilike('display_name', 'b%');
    expect((rows as List).isNotEmpty, isTrue);
  });

  test('RLS prevents updating another user profile', () async {
    await client.from('profiles')
        .update({'display_name': 'Hacked'}).eq('id', kBirukId);
    final row = await client.from('profiles').select('display_name')
        .eq('id', kBirukId).single();
    expect(row['display_name'], isNot('Hacked'));
  });
}
