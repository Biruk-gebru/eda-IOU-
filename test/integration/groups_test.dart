import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  late dynamic client;

  setUpAll(() async { client = await signInAsTestUser(); });
  tearDownAll(() async { await client.auth.signOut(); });

  group('read', () {
    test('TestUser is active in Office Crew', () async {
      final rows = await client.from('group_members').select('status')
          .eq('group_id', kGroupOfficeCrewId).eq('user_id', kTestUserId)
          .eq('status', 'active');
      expect((rows as List).length, 1);
    });

    test('TestUser is active in Addis Trip', () async {
      final rows = await client.from('group_members').select('status')
          .eq('group_id', kGroupAddisTripId).eq('user_id', kTestUserId)
          .eq('status', 'active');
      expect((rows as List).length, 1);
    });

    test('Office Crew active members include Abel, Biruk, Meron, TestUser', () async {
      final rows = await client.from('group_members').select('user_id')
          .eq('group_id', kGroupOfficeCrewId).eq('status', 'active');
      final ids = (rows as List).map((r) => r['user_id'] as String).toSet();
      expect(ids, containsAll([kBirukId, kAbelId, kMeronId, kTestUserId]));
    });

    test('Office Crew detail has correct name and creator', () async {
      final row = await client.from('groups').select('name, creator_id')
          .eq('id', kGroupOfficeCrewId).single();
      expect(row['name'], 'Office Crew');
      expect(row['creator_id'], kBirukId);
    });

    test('get_my_group_ids RPC returns expected groups', () async {
      final ids = (await client.rpc('get_my_group_ids') as List).cast<String>();
      expect(ids, containsAll([kGroupOfficeCrewId, kGroupAddisTripId]));
    });
  });

  group('create / invite / delete', () {
    test('create group, verify membership, delete', () async {
      final g = await client.from('groups').insert({
        'name': '[TEST] Temp Group',
        'creator_id': kTestUserId,
      }).select().single();
      final groupId = g['id'] as String;
      expect(groupId, isUuid());

      await client.from('group_members').insert({
        'group_id': groupId, 'user_id': kTestUserId,
        'role': 'creator', 'status': 'active',
      });
      final m = await client.from('group_members').select('status')
          .eq('group_id', groupId).eq('user_id', kTestUserId).single();
      expect(m['status'], 'active');

      await client.from('group_members').delete().eq('group_id', groupId);
      await client.from('groups').delete().eq('id', groupId);
    });

    test('invite creates pending row; accepting sets active', () async {
      final g = await client.from('groups').insert({
        'name': '[TEST] Invite Group', 'creator_id': kTestUserId,
      }).select().single();
      final gId = g['id'] as String;

      await client.from('group_members').insert([
        {'group_id': gId, 'user_id': kTestUserId, 'role': 'creator', 'status': 'active'},
        {'group_id': gId, 'user_id': kAbelId, 'role': 'member', 'status': 'pending', 'invited_by': kTestUserId},
      ]);

      final inv = await client.from('group_members').select('status')
          .eq('group_id', gId).eq('user_id', kAbelId).single();
      expect(inv['status'], 'pending');

      await client.from('group_members')
          .update({'status': 'active', 'joined_at': DateTime.now().toIso8601String()})
          .eq('group_id', gId).eq('user_id', kAbelId);
      final acc = await client.from('group_members').select('status')
          .eq('group_id', gId).eq('user_id', kAbelId).single();
      expect(acc['status'], 'active');

      await client.from('group_members').delete().eq('group_id', gId);
      await client.from('groups').delete().eq('id', gId);
    });

    test('declining an invitation deletes the row (status CHECK only allows pending/active)', () async {
      final g = await client.from('groups').insert({
        'name': '[TEST] Decline Group', 'creator_id': kTestUserId,
      }).select().single();
      final gId = g['id'] as String;

      await client.from('group_members').insert([
        {'group_id': gId, 'user_id': kTestUserId, 'role': 'creator', 'status': 'active'},
        {'group_id': gId, 'user_id': kMeronId, 'role': 'member', 'status': 'pending', 'invited_by': kTestUserId},
      ]);

      // status CHECK only allows 'pending'|'active' — declining deletes the row
      await client.from('group_members').delete()
          .eq('group_id', gId).eq('user_id', kMeronId);
      final remaining = await client.from('group_members').select('user_id')
          .eq('group_id', gId).eq('user_id', kMeronId);
      expect((remaining as List).isEmpty, isTrue, reason: 'Declined invite is removed');

      await client.from('group_members').delete().eq('group_id', gId);
      await client.from('groups').delete().eq('id', gId);
    });
  });
}
