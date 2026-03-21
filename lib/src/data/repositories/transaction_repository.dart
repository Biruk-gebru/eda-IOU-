import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_participant.dart';

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;
  final _boxName = 'transactions';

  String get _userId => _client.auth.currentUser!.id;

  /// Calls the Supabase RPC to cancel any pending transactions whose
  /// timeout_at has passed. Returns the number of cancelled transactions.
  ///
  /// Note: For server-side automation, enable pg_cron in the Supabase dashboard
  /// and schedule hourly execution:
  ///   SELECT cron.schedule(
  ///     'cancel-expired-transactions',
  ///     '0 * * * *',
  ///     $$SELECT auto_cancel_expired_transactions()$$
  ///   );
  ///   SELECT cron.schedule(
  ///     'expire-payment-requests',
  ///     '0 * * * *',
  ///     $$SELECT auto_expire_payment_requests()$$
  ///   );
  Future<int> checkAndCancelExpired() async {
    try {
      final result =
          await _client.rpc('auto_cancel_expired_transactions');
      return (result as int?) ?? 0;
    } catch (e) {
      // Non-critical — don't block the fetch if cleanup fails
      return 0;
    }
  }

  Future<List<Transaction>> getTransactions() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      return _getLocalTransactions();
    } else {
      try {
        // Cancel expired transactions before fetching
        await checkAndCancelExpired();

        final data = await _client
            .from('transactions')
            .select()
            .order('created_at', ascending: false);

        final transactions =
            (data as List).map((e) => Transaction.fromJson(e)).toList();

        await _cacheTransactions(transactions);
        return transactions;
      } catch (e) {
        return _getLocalTransactions();
      }
    }
  }

  Future<Transaction> getTransaction(String transactionId) async {
    final data = await _client
        .from('transactions')
        .select()
        .eq('id', transactionId)
        .single();
    return Transaction.fromJson(data);
  }

  Future<List<TransactionParticipant>> getParticipants(
      String transactionId) async {
    final data = await _client
        .from('transaction_participants')
        .select()
        .eq('transaction_id', transactionId);
    return (data as List)
        .map((e) => TransactionParticipant.fromJson(e))
        .toList();
  }

  Future<Transaction> createTransaction({
    String? groupId,
    required String payerId,
    required double totalAmount,
    required String description,
    required List<Map<String, dynamic>> participants,
    Duration timeout = const Duration(hours: 48),
  }) async {
    final txData = await _client.from('transactions').insert({
      'group_id': groupId,
      'creator_id': _userId,
      'payer_id': payerId,
      'total_amount': totalAmount,
      'description': description,
      'timeout_at': DateTime.now().add(timeout).toIso8601String(),
    }).select().single();

    final txId = txData['id'];

    // Insert participants
    final participantRows = participants.map((p) => {
          'transaction_id': txId,
          'user_id': p['user_id'],
          'amount_due': p['amount_due'],
        }).toList();

    await _client.from('transaction_participants').insert(participantRows);

    return Transaction.fromJson(txData);
  }

  Future<Map<String, dynamic>> voteTransaction(
      String transactionId, bool approve) async {
    final result = await _client.rpc('rpc_vote_transaction', params: {
      'p_transaction_id': transactionId,
      'p_approve': approve,
    });
    return result as Map<String, dynamic>;
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

    transactions.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
