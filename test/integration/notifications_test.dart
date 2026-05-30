import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  group('Notifications', () {
    test('list notifications returns a list (may be empty)', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('notifications')
          .select()
          .eq('user_id', kBirukId)
          .order('created_at', ascending: false);
      expect(rows, isList);
      await client.auth.signOut();
    });

    test('insert a test notification and verify it is visible', () async {
      final admin = adminClient();
      final inserted = await admin.from('notifications').insert({
        'user_id': kBirukId,
        'type': 'payment_request',
        'title': '[TEST] You have a payment request',
        'body': 'Test body',
        'is_read': false,
        'payload': {'amount': 100},
      }).select().single();
      final nId = inserted['id'] as String;

      final client = await signInAsBiruk();
      final row = await client
          .from('notifications')
          .select()
          .eq('id', nId)
          .single();
      expect(row['is_read'], isFalse);
      expect(row['type'], 'payment_request');

      await admin.from('notifications').delete().eq('id', nId);
      await client.auth.signOut();
    });

    test('mark single notification as read', () async {
      final admin = adminClient();
      final inserted = await admin.from('notifications').insert({
        'user_id': kBirukId,
        'type': 'group_invitation',
        'title': '[TEST] Group invite',
        'body': 'You were invited',
        'is_read': false,
      }).select().single();
      final nId = inserted['id'] as String;

      final client = await signInAsBiruk();
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', nId)
          .eq('user_id', kBirukId);

      final updated = await admin
          .from('notifications')
          .select('is_read')
          .eq('id', nId)
          .single();
      expect(updated['is_read'], isTrue);

      await admin.from('notifications').delete().eq('id', nId);
      await client.auth.signOut();
    });

    test('mark all as read via RPC — all unread count drops to 0', () async {
      final admin = adminClient();
      // Insert two unread notifications
      await admin.from('notifications').insert([
        {
          'user_id': kBirukId,
          'type': 'payment_confirmed',
          'title': '[TEST] Confirmed 1',
          'body': 'body',
          'is_read': false,
        },
        {
          'user_id': kBirukId,
          'type': 'payment_confirmed',
          'title': '[TEST] Confirmed 2',
          'body': 'body',
          'is_read': false,
        },
      ]);

      final client = await signInAsBiruk();
      await client.rpc('mark_all_notifications_read');

      final unread = await client
          .from('notifications')
          .select('id')
          .eq('user_id', kBirukId)
          .eq('is_read', false);
      expect((unread as List).isEmpty, isTrue,
          reason: 'All notifications should be marked read');

      // clean up
      await admin.from('notifications').delete().ilike('title', '[TEST]%').eq('user_id', kBirukId);
      await client.auth.signOut();
    });

    test('getUnreadCount returns correct number', () async {
      final admin = adminClient();
      // clean any existing unread first
      await admin.from('notifications').update({'is_read': true}).eq('user_id', kBirukId).eq('is_read', false);

      await admin.from('notifications').insert([
        {'user_id': kBirukId, 'type': 'transaction_added', 'title': '[TEST] A', 'body': 'x', 'is_read': false},
        {'user_id': kBirukId, 'type': 'transaction_added', 'title': '[TEST] B', 'body': 'x', 'is_read': false},
        {'user_id': kBirukId, 'type': 'transaction_added', 'title': '[TEST] C', 'body': 'x', 'is_read': true},
      ]);

      final client = await signInAsBiruk();
      final rows = await client
          .from('notifications')
          .select('id')
          .eq('user_id', kBirukId)
          .eq('is_read', false);
      expect((rows as List).length, 2);

      // clean up
      await admin.from('notifications').delete().ilike('title', '[TEST]%').eq('user_id', kBirukId);
      await client.auth.signOut();
    });

    test('RLS prevents reading another user notifications', () async {
      final admin = adminClient();
      final inserted = await admin.from('notifications').insert({
        'user_id': kAbelId,
        'type': 'payment_request',
        'title': '[TEST] Abel notif',
        'body': 'private',
        'is_read': false,
      }).select().single();
      final nId = inserted['id'] as String;

      final client = await signInAsBiruk();
      final rows = await client
          .from('notifications')
          .select()
          .eq('id', nId);
      expect((rows as List).isEmpty, isTrue,
          reason: 'Biruk cannot read Abel notifications');

      await admin.from('notifications').delete().eq('id', nId);
      await client.auth.signOut();
    });
  });
}
