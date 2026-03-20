import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/net_balance.dart';

class BalanceRepository {
  BalanceRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<NetBalance>> getBalances() async {
    final data = await _client
        .from('net_balances')
        .select()
        .or('user_a.eq.$_userId,user_b.eq.$_userId')
        .order('last_updated', ascending: false);
    return (data as List).map((e) => NetBalance.fromJson(e)).toList();
  }

  Stream<List<NetBalance>> watchBalances() {
    return _client
        .from('net_balances')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((e) => e['user_a'] == _userId || e['user_b'] == _userId)
            .map((e) => NetBalance.fromJson(e))
            .toList());
  }

  /// Get the total amount the current user owes others.
  double totalOwed(List<NetBalance> balances) {
    double total = 0;
    for (final b in balances) {
      if (b.userA == _userId && b.netAmount > 0) {
        total += b.netAmount; // user_a owes user_b
      } else if (b.userB == _userId && b.netAmount < 0) {
        total += b.netAmount.abs(); // user_b owes user_a (negative means reverse)
      }
    }
    return total;
  }

  /// Get the total amount others owe the current user.
  double totalOwedToMe(List<NetBalance> balances) {
    double total = 0;
    for (final b in balances) {
      if (b.userA == _userId && b.netAmount < 0) {
        total += b.netAmount.abs();
      } else if (b.userB == _userId && b.netAmount > 0) {
        total += b.netAmount;
      }
    }
    return total;
  }
}
