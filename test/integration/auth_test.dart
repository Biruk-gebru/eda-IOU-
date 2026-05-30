import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_config.dart';

void main() {
  group('Auth', () {
    test('sign in with valid credentials returns authenticated user', () async {
      final client = SupabaseClient(kSupabaseUrl, kAnonKey);
      final res = await client.auth.signInWithPassword(
        email: kTestEmail,
        password: kTestPassword,
      );
      expect(res.user, isNotNull);
      expect(res.user!.id, kBirukId);
      expect(res.session, isNotNull);
      await client.auth.signOut();
    });

    test('sign in with wrong password throws AuthException', () async {
      final client = SupabaseClient(kSupabaseUrl, kAnonKey);
      expect(
        () => client.auth.signInWithPassword(
          email: kTestEmail,
          password: 'definitely_wrong_password_xyz',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('currentUser is null before sign-in', () async {
      final client = SupabaseClient(kSupabaseUrl, kAnonKey);
      expect(client.auth.currentUser, isNull);
    });

    test('currentUser is populated after sign-in', () async {
      final client = await signInAsBiruk();
      expect(client.auth.currentUser, isNotNull);
      expect(client.auth.currentUser!.id, kBirukId);
      await client.auth.signOut();
    });

    test('currentUser is null after sign-out', () async {
      final client = await signInAsBiruk();
      await client.auth.signOut();
      expect(client.auth.currentUser, isNull);
    });

    test('authenticated session includes a valid JWT', () async {
      final client = await signInAsBiruk();
      final session = client.auth.currentSession;
      expect(session, isNotNull);
      expect(session!.accessToken, isNotEmpty);
      await client.auth.signOut();
    });
  });
}
