import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  late dynamic client;

  setUpAll(() async {
    client = await signInAsTestUser();
    // Ensure all TestUser notifications start as unread for predictable counts.
    await client.from('notifications')
        .update({'read': false})
        .eq('user_id', kTestUserId);
  });
  tearDownAll(() async { await client.auth.signOut(); });

  test('pre-seeded notifications are visible', () async {
    final rows = await client.from('notifications').select()
        .eq('user_id', kTestUserId);
    expect((rows as List).length, greaterThanOrEqualTo(3));
  });

  test('unread count is at least 2', () async {
    final rows = await client.from('notifications').select('id')
        .eq('user_id', kTestUserId).eq('read', false);
    expect((rows as List).length, greaterThanOrEqualTo(2));
  });

  test('mark single notification as read then restore', () async {
    final unread = await client.from('notifications').select('id')
        .eq('user_id', kTestUserId).eq('read', false).limit(1);
    final nId = (unread as List).first['id'] as String;

    await client.from('notifications').update({'read': true})
        .eq('id', nId).eq('user_id', kTestUserId);
    final updated = await client.from('notifications').select('read')
        .eq('id', nId).single();
    expect(updated['read'], isTrue);

    await client.from('notifications').update({'read': false})
        .eq('id', nId).eq('user_id', kTestUserId);
  });

  test('mark all as read — none remain unread', () async {
    await client.from('notifications').update({'read': true})
        .eq('user_id', kTestUserId).eq('read', false);

    final unread = await client.from('notifications').select('id')
        .eq('user_id', kTestUserId).eq('read', false);
    expect((unread as List).isEmpty, isTrue);

    // Restore all to unread for subsequent tests
    await client.from('notifications').update({'read': false})
        .eq('user_id', kTestUserId);
  });

  test('insert own notification and delete it', () async {
    // RLS INSERT WITH CHECK only allows type='group_invitation' for authenticated users
    final row = await client.from('notifications').insert({
      'user_id': kTestUserId, 'type': 'group_invitation',
      'payload': {'note': '[TEST] own notification'}, 'read': false,
    }).select().single();
    expect(row['id'], isUuid());
    expect(row['read'], isFalse);
    await client.from('notifications').delete().eq('id', row['id']);
  });

  test('RLS: cannot read Biruk notifications', () async {
    final rows = await client.from('notifications').select('id')
        .eq('user_id', kBirukId);
    expect((rows as List).isEmpty, isTrue);
  });
}
