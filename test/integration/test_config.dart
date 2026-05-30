// Shared constants and helpers for all integration tests.
//
// Run with:
//   flutter test test/integration/ --concurrency=1
//
// No dart-defines needed — credentials are hardcoded for the dedicated
// test user created specifically for this suite.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Connection ───────────────────────────────────────────────────────────────

const kSupabaseUrl = 'https://xevsusqvphlhxlcndvpt.supabase.co';
const kAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhldnN1c3F2cGhsaHhsY25kdnB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxNTI2NjYsImV4cCI6MjA3ODcyODY2Nn0'
    '.rat7H6YUqzOwJB4_oOsOCaRlTWwlM_muATo_0t8taqc';

// ── Dedicated test user (created via SQL, never touches real user data) ───────

const kTestUserId = 'ffffffff-ffff-4fff-bfff-ffffffffffff';
const kTestEmail   = 'test@eda.test';
const kTestPassword = 'TestEda2024!';

// ── Known production mock user IDs (read-only reference in tests) ─────────────

const kBirukId  = '425b66ea-19e6-4f7d-8a1b-4df32585e0b3';
const kAbelId   = 'a6eebdc0-1d6d-4e67-a014-1c837ccdf398';
const kMeronId  = '11cca4ac-4c48-4a4d-9e9f-2bc0295add25';
const kBisratId = '1a56eece-916f-49a0-bfd8-cbed28b5e12e';
const kKaleabId = 'dbc4088d-1d52-42e8-b053-d39dd32be866';

// ── Group IDs ────────────────────────────────────────────────────────────────

const kGroupAddisTripId  = 'aaaaaaaa-0001-4000-8000-000000000001';
const kGroupOfficeCrewId = 'aaaaaaaa-0001-4000-8000-000000000002';
const kGroupRoommatesId  = '02aa819a-692c-4842-9b60-a5bc30faa430';

// ── Net balance layout for TestUser (pre-seeded) ──────────────────────────────
// UUID lex order: Meron(11) < Bisrat(1a) < Biruk(42) < Abel(a6) < TestUser(ff)
//
//  Abel(a6) < TestUser(ff):  user_a=Abel,  user_b=TestUser, net= 80  → Abel owes TestUser 80
//  Meron(11) < TestUser(ff): user_a=Meron, user_b=TestUser, net=-120 → TestUser owes Meron 120
//
// Routing 10 via (Abel→TestUser→Meron):
//   Abel→TestUser: net 80→70   (Abel still owes TestUser 70)
//   TestUser→Meron: net -120→-110  (TestUser owes Meron 110)
//
// Restore (reverse chain, same amount):
//   [{debtor:TestUser, creditor:Abel}, {debtor:Meron, creditor:TestUser}]

/// Sign in once and return a long-lived client.
/// Call in setUpAll; sign out in tearDownAll.
Future<SupabaseClient> signInAsTestUser() async {
  final client = SupabaseClient(kSupabaseUrl, kAnonKey);
  final res = await client.auth.signInWithPassword(
    email: kTestEmail,
    password: kTestPassword,
  );
  if (res.user == null) throw Exception('Test user sign-in failed');
  return client;
}

/// Convenience: sign in, run [body], sign out — for quick one-shot tests.
Future<T> withTestUser<T>(Future<T> Function(SupabaseClient) body) async {
  final client = await signInAsTestUser();
  try {
    return await body(client);
  } finally {
    await client.auth.signOut();
  }
}


// ── Matcher ──────────────────────────────────────────────────────────────────

Matcher isUuid() => matches(
  RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'),
);
