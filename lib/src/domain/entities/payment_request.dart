import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_request.freezed.dart';

@freezed
class PaymentRequest with _$PaymentRequest {
  const factory PaymentRequest({
    required String id,
    required String payerId,
    required String receiverId,
    required double amount,
    String? relatedTransactionId,
    String? groupId,
    required String status,
    String? method,
    String? note,
    required DateTime createdAt,
    DateTime? confirmedAt,
  }) = _PaymentRequest;

  const PaymentRequest._();
}
