import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_request.freezed.dart';
part 'payment_request.g.dart';

@freezed
class PaymentRequest with _$PaymentRequest {
  const factory PaymentRequest({
    required String id,
    @JsonKey(name: 'payer_id') required String payerId,
    @JsonKey(name: 'receiver_id') required String receiverId,
    required double amount,
    @JsonKey(name: 'related_transaction_id') String? relatedTransactionId,
    @JsonKey(name: 'group_id') String? groupId,
    @Default('pending') String status,
    String? method,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'confirmed_at') DateTime? confirmedAt,
    @JsonKey(name: 'timeout_at') DateTime? timeoutAt,
  }) = _PaymentRequest;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);

  const PaymentRequest._();
}
