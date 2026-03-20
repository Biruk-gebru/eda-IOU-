import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/transaction.dart';

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;
  final _boxName = 'transactions';

  Future<List<Transaction>> getTransactions() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      return _getLocalTransactions();
    } else {
      try {
        final data = await _client
            .from('transactions')
            .select()
            .order('created_at', ascending: false);
        
        final transactions = (data as List)
            .map((e) => Transaction.fromJson(e))
            .toList();
        
        await _cacheTransactions(transactions);
        return transactions;
      } catch (e) {
        // Fallback to local if fetch fails
        return _getLocalTransactions();
      }
    }
  }

  Future<List<Transaction>> _getLocalTransactions() async {
    final box = await Hive.openBox<String>(_boxName);
    final List<Transaction> transactions = [];
    
    for (var i = 0; i < box.length; i++) {
      final jsonString = box.getAt(i);
      if (jsonString != null) {
        try {
          transactions.add(Transaction.fromJson(jsonDecode(jsonString)));
        } catch (e) {
          // Ignore malformed data
        }
      }
    }
    
    // Sort by created_at desc locally as well
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  Future<void> _cacheTransactions(List<Transaction> transactions) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.clear();
    
    final Map<int, String> entries = {};
    for (var i = 0; i < transactions.length; i++) {
      entries[i] = jsonEncode(transactions[i].toJson());
    }
    
    await box.putAll(entries);
  }
}
