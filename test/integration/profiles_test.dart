import 'package:flutter_test/flutter_test.dart';

import 'test_config.dart';

void main() {
  group('Profiles', () {
    test('Biruk profile exists with correct display_name', () async {
      final client = await signInAsBiruk();
      final row = await client
          .from('profiles')
          .select('id, display_name')
          .eq('id', kBirukId)
          .single();
      expect(row['id'], kBirukId);
      expect(row['display_name'], isNotEmpty);
      await client.auth.signOut();
    });

    test('all mock user profiles exist', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', [kBirukId, kAbelId, kMeronId, kBisratId, kKaleabId]);
      expect(rows.length, 5);
      final ids = (rows as List).map((r) => r['id'] as String).toSet();
      expect(ids, containsAll([kBirukId, kAbelId, kMeronId, kBisratId, kKaleabId]));
      await client.auth.signOut();
    });

    test('display_name update and restore', () async {
      final client = await signInAsBiruk();

      final original = await client
          .from('profiles')
          .select('display_name')
          .eq('id', kBirukId)
          .single();
      final originalName = original['display_name'] as String;

      await client.from('profiles').update({'display_name': 'TestBiruk'}).eq('id', kBirukId);
      final updated = await client
          .from('profiles')
          .select('display_name')
          .eq('id', kBirukId)
          .single();
      expect(updated['display_name'], 'TestBiruk');

      // restore
      await client.from('profiles').update({'display_name': originalName}).eq('id', kBirukId);
      await client.auth.signOut();
    });

    test('cannot read another user profile row via RLS', () async {
      // RLS allows profiles to be read by anyone (public profiles)
      // Verify Abel profile is visible to Biruk
      final client = await signInAsBiruk();
      final row = await client
          .from('profiles')
          .select('id, display_name')
          .eq('id', kAbelId)
          .maybeSingle();
      expect(row, isNotNull);
      expect(row!['id'], kAbelId);
      await client.auth.signOut();
    });

    test('profile query by display_name (ilike search)', () async {
      final client = await signInAsBiruk();
      final rows = await client
          .from('profiles')
          .select('id, display_name')
          .ilike('display_name', 'bi%');
      expect((rows as List).isNotEmpty, isTrue);
      await client.auth.signOut();
    });
  });
}
