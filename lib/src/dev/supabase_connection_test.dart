import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/di/di.dart';

/// Entry point for running Supabase connectivity tests without a UI.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();

  final tester = SupabaseConnectionTester(Supabase.instance.client);
  stdout.writeln('🔌 Supabase Connection Tester');
  stdout.writeln('================================');
  stdout.writeln(
    'This tool lets you manually trigger the helper functions from '
    'Part 6 of SUPABASE_SETUP.md without building UI screens.',
  );
  stdout.writeln(
    '\nRun this with: flutter run -d linux -t lib/src/dev/supabase_connection_test.dart',
  );
  stdout.writeln('Press Ctrl+C to exit at any time.\n');

  while (true) {
    stdout.writeln('Choose an action:');
    stdout.writeln('1) signInWithGoogle');
    stdout.writeln('2) signInWithEmail');
    stdout.writeln('3) testDatabase');
    stdout.writeln('q) quit');
    stdout.write('> ');

    final input = stdin.readLineSync()?.trim();
    if (input == null) {
      stdout.writeln('No input detected. Please try again.\n');
      continue;
    }

    if (input.toLowerCase() == 'q') {
      stdout.writeln('Exiting Supabase Connection Tester. Bye! 👋');
      exit(0);
    }

    switch (input) {
      case '1':
        await tester.signInWithGoogle();
        break;
      case '2':
        await tester.signInWithEmail();
        break;
      case '3':
        await tester.testDatabase();
        break;
      default:
        stdout.writeln(
          'Unknown option "$input". Please choose 1, 2, 3 or q.\n',
        );
    }
  }
}

class SupabaseConnectionTester {
  SupabaseConnectionTester(this._client);

  final SupabaseClient _client;

  static const _redirectUri = 'com.example.eda://login-callback/';

  /// Launches the Google OAuth flow.
  ///
  /// NOTE:
  /// * Run this on Android or iOS (or an emulator) where your deep link is
  ///   configured. Desktop platforms do not yet support custom scheme redirects.
  /// * The browser will open and you must complete the flow manually.
  Future<void> signInWithGoogle() async {
    stdout.writeln('Launching Google OAuth flow...');
    stdout.writeln('Complete the sign-in in the browser that opens.');

    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUri,
      );
      stdout.writeln(
        'Google OAuth flow launched. Wait for the app to receive the deep link.',
      );
    } on AuthException catch (error) {
      stdout.writeln('Google OAuth failed: ${error.message}');
    } catch (error) {
      stdout.writeln('Unexpected error during Google OAuth: $error');
    }

    stdout.writeln('');
  }

  /// Performs email/password authentication for quick verification.
  ///
  /// Prompts for email and password in the terminal to avoid hardcoding secrets.
  Future<void> signInWithEmail() async {
    stdout.write('Email: ');
    final email = stdin.readLineSync();

    stdout.write('Password (input hidden is not supported, type carefully): ');
    final password = stdin.readLineSync();

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      stdout.writeln('Email and password are required.\n');
      return;
    }

    stdout.writeln('Attempting email/password sign-in...');

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final userEmail = response.user?.email ?? 'unknown';
      stdout.writeln('✅ Sign-in successful for $userEmail');
    } on AuthException catch (error) {
      stdout.writeln('❌ Email/password sign-in failed: ${error.message}');
    } catch (error) {
      stdout.writeln('Unexpected error during email/password sign-in: $error');
    }

    stdout.writeln('');
  }

  /// Runs a simple select query against the `profiles` table to verify DB access.
  Future<void> testDatabase() async {
    stdout.writeln('Querying `profiles` table (limit 1)...');

    try {
      final rows = await _client.from('profiles').select().limit(1);
      stdout.writeln('✅ Database query succeeded. Result: $rows');
    } on PostgrestException catch (error) {
      stdout.writeln('❌ Database query failed: ${error.message}');
    } catch (error) {
      stdout.writeln('Unexpected error during database query: $error');
    }

    stdout.writeln('');
  }
}

