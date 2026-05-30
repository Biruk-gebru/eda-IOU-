import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_config.dart';

void main() {
  // Auth tests create their own short-lived clients intentionally.

  test('sign in returns correct user id', () async {
    final client = SupabaseClient(kSupabaseUrl, kAnonKey);
    final res = await client.auth
        .signInWithPassword(email: kTestEmail, password: kTestPassword);
    expect(res.user?.id, kTestUserId);
    expect(res.session?.accessToken, isNotEmpty);
    await client.auth.signOut();
  });

  test('currentUser is null before sign-in', () {
    final client = SupabaseClient(kSupabaseUrl, kAnonKey);
    expect(client.auth.currentUser, isNull);
  });

  test('currentUser is null after sign-out', () async {
    final client = await signInAsTestUser();
    await client.auth.signOut();
    expect(client.auth.currentUser, isNull);
  });

  test('wrong password throws AuthException', () async {
    final client = SupabaseClient(kSupabaseUrl, kAnonKey);
    await expectLater(
      client.auth
          .signInWithPassword(email: kTestEmail, password: 'bad_password'),
      throwsA(isA<AuthException>()),
    );
  });

  test('unauthenticated client cannot read net_balances', () async {
    final client = SupabaseClient(kSupabaseUrl, kAnonKey);
    final rows = await client
        .from('net_balances')
        .select()
        .eq('user_b', kTestUserId);
    expect((rows as List).isEmpty, isTrue);
  });
}
