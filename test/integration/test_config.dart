// Shared constants and helpers for all integration tests.
// Run with:
//   flutter test test/integration/ \
//     --dart-define=TEST_EMAIL=<email> \
//     --dart-define=TEST_PASSWORD=<password> \
//     --dart-define=SUPABASE_SERVICE_ROLE_KEY=<service_role_key>

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Connection ───────────────────────────────────────────────────────────────

const kSupabaseUrl = 'https://xevsusqvphlhxlcndvpt.supabase.co';
const kAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhldnN1c3F2cGhsaHhsY25kdnB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxNTI2NjYsImV4cCI6MjA3ODcyODY2Nn0'
    '.rat7H6YUqzOwJB4_oOsOCaRlTWwlM_muATo_0t8taqc';

// Provided via --dart-define at test time.
const kTestEmail =
    String.fromEnvironment('TEST_EMAIL');
const kTestPassword =
    String.fromEnvironment('TEST_PASSWORD');
const kServiceRoleKey =
    String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

// ── Known user IDs (production mock users) ───────────────────────────────────

const kBirukId  = '425b66ea-19e6-4f7d-8a1b-4df32585e0b3'; // authenticated user
const kAbelId   = 'a6eebdc0-1d6d-4e67-a014-1c837ccdf398';
const kMeronId  = '11cca4ac-4c48-4a4d-9e9f-2bc0295add25';
const kBisratId = '1a56eece-916f-49a0-bfd8-cbed28b5e12e';
const kKaleabId = 'dbc4088d-1d52-42e8-b053-d39dd32be866';

// ── Known group IDs ──────────────────────────────────────────────────────────

const kGroupAddisTripId  = 'aaaaaaaa-0001-4000-8000-000000000001'; // Biruk, Bisrat, Kaleab
const kGroupOfficeCrewId = 'aaaaaaaa-0001-4000-8000-000000000002'; // Abel, Biruk, Meron
const kGroupRoommatesId  = '02aa819a-692c-4842-9b60-a5bc30faa430'; // Biruk, Bisrat, Meron

// ── Client factories ─────────────────────────────────────────────────────────

/// Creates an authenticated client signed in as Biruk.
Future<SupabaseClient> signInAsBiruk() async {
  final client = SupabaseClient(kSupabaseUrl, kAnonKey);
  final res = await client.auth.signInWithPassword(
    email: kTestEmail,
    password: kTestPassword,
  );
  if (res.user == null) throw Exception('Sign-in failed — check TEST_EMAIL/TEST_PASSWORD');
  return client;
}

/// Returns a service-role client that bypasses RLS.
/// Requires SUPABASE_SERVICE_ROLE_KEY to be set.
SupabaseClient adminClient() {
  if (kServiceRoleKey.isEmpty) {
    throw Exception('SUPABASE_SERVICE_ROLE_KEY not set — required for this test');
  }
  return SupabaseClient(kSupabaseUrl, kServiceRoleKey);
}

// ── Hive setup for repositories that use local cache ────────────────────────

late Directory _hiveDir;

Future<void> initHive() async {
  _hiveDir = await Directory.systemTemp.createTemp('eda_test_hive_');
  Hive.init(_hiveDir.path);
}

Future<void> tearDownHive() async {
  await Hive.close();
  try { await _hiveDir.delete(recursive: true); } catch (_) {}
}

// ── Snapshot / restore helpers ───────────────────────────────────────────────

/// Snapshot all net_balances rows and return them for later restoration.
Future<List<Map<String, dynamic>>> snapshotNetBalances(
    SupabaseClient admin) async {
  final rows = await admin.from('net_balances').select();
  return List<Map<String, dynamic>>.from(rows as List);
}

/// Restore net_balances to the snapshot by deleting all rows and re-inserting.
Future<void> restoreNetBalances(
    SupabaseClient admin, List<Map<String, dynamic>> snapshot) async {
  await admin.from('net_balances').delete().neq('net_amount', 999999999);
  if (snapshot.isNotEmpty) {
    final rows = snapshot.map((r) => {
      'user_a': r['user_a'],
      'user_b': r['user_b'],
      'net_amount': r['net_amount'],
    }).toList();
    await admin.from('net_balances').insert(rows);
  }
}

// ── Matchers ─────────────────────────────────────────────────────────────────

Matcher isUuid() => matches(
  RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'),
);
