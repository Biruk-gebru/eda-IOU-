import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/payment_repository.dart';
import '../../domain/entities/payment_request.dart';
import 'auth_providers.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PaymentRepository(client);
});

final paymentRequestsProvider =
    StreamProvider<List<PaymentRequest>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchPaymentRequests();
});

final groupPaymentRequestsProvider =
    FutureProvider.family<List<PaymentRequest>, String>((ref, groupId) async {
  return ref.watch(paymentRepositoryProvider).getGroupPaymentRequests(groupId);
});
