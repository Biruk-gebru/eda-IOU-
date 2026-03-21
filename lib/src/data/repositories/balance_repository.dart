import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/net_balance.dart';

class BalanceRepository {
  BalanceRepository(this._client);

  final SupabaseClient _client;
  static const _boxName = 'balances_cache';

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<NetBalance>> getBalances() async {
    final userId = _userId;
    if (userId == null) return _getCachedBalances();

    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    if (isOffline) return _getCachedBalances();

    try {
      final data = await _client
          .from('net_balances')
          .select()
          .or('user_a.eq.$userId,user_b.eq.$userId')
          .order('last_updated', ascending: false);
      final balances =
          (data as List).map((e) => NetBalance.fromJson(e)).toList();
      await _cacheBalances(balances);
      return balances;
    } catch (e) {
      return _getCachedBalances();
    }
  }

  Stream<List<NetBalance>> watchBalances() {
    final userId = _userId;
    return _client
        .from('net_balances')
        .stream(primaryKey: ['id']).map((data) {
      final balances = data
          .where((e) => e['user_a'] == userId || e['user_b'] == userId)
          .map((e) => NetBalance.fromJson(e))
          .toList();
      _cacheBalances(balances);
      return balances;
    }).handleError((_) {});
  }

  double totalOwed(List<NetBalance> balances) {
    final userId = _userId;
    double total = 0;
    for (final b in balances) {
      if (b.userA == userId && b.netAmount > 0) {
        total += b.netAmount;
      } else if (b.userB == userId && b.netAmount < 0) {
        total += b.netAmount.abs();
      }
    }
    return total;
  }

  double totalOwedToMe(List<NetBalance> balances) {
    final userId = _userId;
    double total = 0;
    for (final b in balances) {
      if (b.userA == userId && b.netAmount < 0) {
        total += b.netAmount.abs();
      } else if (b.userB == userId && b.netAmount > 0) {
        total += b.netAmount;
      }
    }
    return total;
  }

  // Caching
  Future<List<NetBalance>> _getCachedBalances() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final List<NetBalance> balances = [];
      for (var i = 0; i < box.length; i++) {
        final json = box.getAt(i);
        if (json != null) {
          try {
            balances.add(NetBalance.fromJson(jsonDecode(json)));
          } catch (_) {}
        }
      }
      return balances;
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheBalances(List<NetBalance> balances) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.clear();
      for (var i = 0; i < balances.length; i++) {
        await box.put(i, jsonEncode(balances[i].toJson()));
      }
    } catch (_) {}
  }
}
