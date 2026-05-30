import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  group('Groups — read existing', () {
    test('Biruk is active member of Office Crew', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('group_members')
          .select('group_id, status')
          .eq('user_id', kBirukId)
          .eq('group_id', kGroupOfficeCrewId)
          .eq('status', 'active');
      expect((rows as List).length, 1);
      await client.auth.signOut();
    });

    test('Office Crew has exactly Abel, Biruk, Meron as active members', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('group_members')
          .select('user_id')
          .eq('group_id', kGroupOfficeCrewId)
          .eq('status', 'active');
      final ids = (rows as List).map((r) => r['user_id'] as String).toSet();
      expect(ids, containsAll([kBirukId, kAbelId, kMeronId]));
      expect(ids.length, 3);
      await client.auth.signOut();
    });

    test('Addis Trip has Biruk, Bisrat, Kaleab as active members', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('group_members')
          .select('user_id')
          .eq('group_id', kGroupAddisTripId)
          .eq('status', 'active');
      final ids = (rows as List).map((r) => r['user_id'] as String).toSet();
      expect(ids, containsAll([kBirukId, kBisratId, kKaleabId]));
      await client.auth.signOut();
    });

    test('get group detail returns correct name and creator', () async {
      final client = await signInAsBiruk();
      final row = await client
          .from('groups')
          .select('id, name, creator_id')
          .eq('id', kGroupOfficeCrewId)
          .single();
      expect(row['name'], 'Office Crew');
      expect(row['creator_id'], kBirukId);
      await client.auth.signOut();
    });

    test('Biruk belongs to 3 known groups', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('group_members')
          .select('group_id')
          .eq('user_id', kBirukId)
          .eq('status', 'active');
      final ids = (rows as List).map((r) => r['group_id'] as String).toSet();
      expect(
        ids,
        containsAll([kGroupAddisTripId, kGroupOfficeCrewId, kGroupRoommatesId]),
      );
      await client.auth.signOut();
    });
  });

  group('Groups — create / invite / delete', () {
    test('create a group, verify it exists, delete it', () async {
      final client = await signInAsBiruk();

      final inserted = await client.from('groups').insert({
        'name': '[TEST] Temp Group',
        'creator_id': kBirukId,
      }).select().single();
      final groupId = inserted['id'] as String;
      expect(groupId, isUuid());

      // creator auto-added as active member (trigger or manual)
      await client.from('group_members').insert({
        'group_id': groupId,
        'user_id': kBirukId,
        'role': 'creator',
        'status': 'active',
      });

      final member = await client
          .from('group_members')
          .select('status')
          .eq('group_id', groupId)
          .eq('user_id', kBirukId)
          .single();
      expect(member['status'], 'active');

      // clean up
      await client.from('group_members').delete().eq('group_id', groupId);
      await client.from('groups').delete().eq('id', groupId);
      await client.auth.signOut();
    });

    test('invite a member — pending row is created', () async {
      final client = await signInAsBiruk();

      // create temp group
      final g = await client.from('groups').insert({
        'name': '[TEST] Invite Group',
        'creator_id': kBirukId,
      }).select().single();
      final groupId = g['id'] as String;
      await client.from('group_members').insert({
        'group_id': groupId,
        'user_id': kBirukId,
        'role': 'creator',
        'status': 'active',
      });

      // invite Abel
      await client.from('group_members').insert({
        'group_id': groupId,
        'user_id': kAbelId,
        'role': 'member',
        'status': 'pending',
        'invited_by': kBirukId,
      });

      final invitation = await client
          .from('group_members')
          .select('status')
          .eq('group_id', groupId)
          .eq('user_id', kAbelId)
          .single();
      expect(invitation['status'], 'pending');

      // simulate Abel accepting (update via admin to bypass RLS on other user)
      final admin = adminClient();
      await admin.from('group_members').update({
        'status': 'active',
        'joined_at': DateTime.now().toIso8601String(),
      }).eq('group_id', groupId).eq('user_id', kAbelId);

      final accepted = await client
          .from('group_members')
          .select('status')
          .eq('group_id', groupId)
          .eq('user_id', kAbelId)
          .single();
      expect(accepted['status'], 'active');

      // clean up
      await admin.from('group_members').delete().eq('group_id', groupId);
      await admin.from('groups').delete().eq('id', groupId);
      await client.auth.signOut();
    });

    test('decline invitation sets status to declined (not deleted)', () async {
      final client = await signInAsBiruk();
      final admin = adminClient();

      final g = await client.from('groups').insert({
        'name': '[TEST] Decline Group',
        'creator_id': kBirukId,
      }).select().single();
      final groupId = g['id'] as String;

      await admin.from('group_members').insert([
        {'group_id': groupId, 'user_id': kBirukId, 'role': 'creator', 'status': 'active'},
        {'group_id': groupId, 'user_id': kMeronId, 'role': 'member', 'status': 'pending', 'invited_by': kBirukId},
      ]);

      // Meron declines — should update to 'declined' (preserving audit trail)
      await admin.from('group_members').update({'status': 'declined'})
          .eq('group_id', groupId)
          .eq('user_id', kMeronId);

      final row = await admin
          .from('group_members')
          .select('status')
          .eq('group_id', groupId)
          .eq('user_id', kMeronId)
          .single();
      expect(row['status'], 'declined');

      // clean up
      await admin.from('group_members').delete().eq('group_id', groupId);
      await admin.from('groups').delete().eq('id', groupId);
      await client.auth.signOut();
    });
  });
}
