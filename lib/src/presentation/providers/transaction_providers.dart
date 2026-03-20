import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/transaction_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_participant.dart';
import 'auth_providers.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TransactionRepository(client);
});

final transactionListProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});

final transactionDetailProvider =
    FutureProvider.family<Transaction, String>((ref, id) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransaction(id);
});

final transactionParticipantsProvider =
    FutureProvider.family<List<TransactionParticipant>, String>(
        (ref, transactionId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getParticipants(transactionId);
});
