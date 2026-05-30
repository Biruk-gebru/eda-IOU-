import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  group('Banking accounts', () {
    test('can insert a Telebirr account and delete it', () async {
      final client = await signInAsBiruk();

      final inserted = await client.from('banking_accounts').insert({
        'user_id': kBirukId,
        'bank_type': 'Telebirr',
        'account_identifier': '0911000000',
        'account_holder_name': 'Test Holder',
      }).select().single();

      final id = inserted['id'] as String;
      expect(id, isNotEmpty);
      expect(inserted['bank_type'], 'Telebirr');

      // verify it's readable back
      final rows = await client
          .from('banking_accounts')
          .select()
          .eq('user_id', kBirukId)
          .eq('id', id);
      expect((rows as List).length, 1);

      // clean up
      await client.from('banking_accounts').delete().eq('id', id);
      await client.auth.signOut();
    });

    test('can insert a CBE account and delete it', () async {
      final client = await signInAsBiruk();

      final inserted = await client.from('banking_accounts').insert({
        'user_id': kBirukId,
        'bank_type': 'CBE',
        'account_identifier': '1000123456789',
        'account_holder_name': 'Test Holder CBE',
      }).select().single();

      final id = inserted['id'] as String;
      expect(inserted['bank_type'], 'CBE');

      await client.from('banking_accounts').delete().eq('id', id);
      await client.auth.signOut();
    });

    test('RLS prevents reading another user banking accounts', () async {
      // Insert an account for Abel via admin
      final admin = adminClient();
      final adminInserted = await admin.from('banking_accounts').insert({
        'user_id': kAbelId,
        'bank_type': 'Telebirr',
        'account_identifier': '0922000001',
        'account_holder_name': 'Abel Test',
      }).select().single();
      final adminId = adminInserted['id'] as String;

      // Biruk should NOT be able to see Abel's account
      final client = await signInAsBiruk();
      final rows = await client
          .from('banking_accounts')
          .select()
          .eq('id', adminId);
      expect((rows as List).isEmpty, isTrue);

      await admin.from('banking_accounts').delete().eq('id', adminId);
      await client.auth.signOut();
    });

    test('list all of Biruk banking accounts', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('banking_accounts')
          .select()
          .eq('user_id', kBirukId);
      // Just verifies the query succeeds and returns a list
      expect(rows, isList);
      await client.auth.signOut();
    });
  });
}
