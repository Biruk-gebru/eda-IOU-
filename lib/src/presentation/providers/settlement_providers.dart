import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settlement_repository.dart';
import '../../domain/entities/settlement_request.dart';
import 'auth_providers.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SettlementRepository(client);
});

final settlementRequestsProvider =
    StreamProvider<List<SettlementRequest>>((ref) {
  final repository = ref.watch(settlementRepositoryProvider);
  return repository.watchSettlementRequests();
});
