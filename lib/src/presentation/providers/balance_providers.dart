import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/balance_repository.dart';
import '../../domain/entities/net_balance.dart';
import 'auth_providers.dart';

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BalanceRepository(client);
});

final balancesProvider = FutureProvider<List<NetBalance>>((ref) async {
  final repository = ref.watch(balanceRepositoryProvider);
  return repository.getBalances();
});
