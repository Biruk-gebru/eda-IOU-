import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  late dynamic client;

  setUpAll(() async { client = await signInAsTestUser(); });
  tearDownAll(() async { await client.auth.signOut(); });

  test('insert Telebirr account and delete it', () async {
    final row = await client.from('banking_accounts').insert({
      'user_id': kTestUserId,
      'bank_type': 'Telebirr',
      'account_identifier': '0911000099',
      'account_name': 'Test Holder',
    }).select().single();
    final id = row['id'] as String;
    expect(id, isUuid());
    expect(row['bank_type'], 'Telebirr');
    await client.from('banking_accounts').delete().eq('id', id);
  });

  test('insert CBE account and delete it', () async {
    final row = await client.from('banking_accounts').insert({
      'user_id': kTestUserId,
      'bank_type': 'CBE',
      'account_identifier': '1000987654321',
      'account_name': 'Test CBE',
    }).select().single();
    final id = row['id'] as String;
    expect(row['bank_type'], 'CBE');
    await client.from('banking_accounts').delete().eq('id', id);
  });

  test('cannot read Biruk banking accounts (RLS)', () async {
    final rows = await client.from('banking_accounts').select()
        .eq('user_id', kBirukId);
    expect((rows as List).isEmpty, isTrue);
  });

  test('listed own accounts all have own user_id', () async {
    final inserted = await client.from('banking_accounts').insert({
      'user_id': kTestUserId,
      'bank_type': 'Zemen',
      'account_identifier': '9001',
      'account_name': 'Zemen Test',
    }).select().single();

    final rows = await client.from('banking_accounts').select()
        .eq('user_id', kTestUserId);
    expect((rows as List).isNotEmpty, isTrue);
    for (final r in rows) { expect(r['user_id'], kTestUserId); }

    await client.from('banking_accounts').delete().eq('id', inserted['id']);
  });
}
