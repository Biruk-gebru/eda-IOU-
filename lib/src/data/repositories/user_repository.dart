import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../domain/entities/user.dart';

class UserRepository {
  UserRepository(this._client);

  final SupabaseClient _client;
  final _boxName = 'user_profile';
  final _key = 'current_user';

  Future<User?> getCurrentUser() async {
    // Try local first for speed
    final localUser = await _getLocalUser();
    
    // Sync with remote if connected
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          final data = await _client
              .from('profiles')
              .select()
              .eq('id', userId)
              .single();
          
          final user = User.fromJson(data);
          await _cacheUser(user);
          return user;
        }
      } catch (e) {
        // Fallback to local
      }
    }
    
    return localUser;
  }

  Future<void> updateUser(User user) async {
    // Optimistic update
    await _cacheUser(user);

    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        await _client.from('profiles').upsert(user.toJson());
      } catch (e) {
        // Queue for sync later (simplified: just ignore for now)
        rethrow;
      }
    } else {
      throw Exception('No internet connection');
    }
  }

  Future<User?> _getLocalUser() async {
    final box = await Hive.openBox<String>(_boxName);
    final jsonString = box.get(_key);
    if (jsonString != null) {
      try {
        return User.fromJson(jsonDecode(jsonString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _cacheUser(User user) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, jsonEncode(user.toJson()));
  }
}
