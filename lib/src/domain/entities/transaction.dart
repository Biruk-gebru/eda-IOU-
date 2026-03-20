import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    @JsonKey(name: 'group_id') String? groupId,
    String? description,
    @JsonKey(name: 'creator_id') required String creatorId,
    @JsonKey(name: 'payer_id') required String payerId,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @Default('ETB') String currency,
    Map<String, dynamic>? metadata,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'timeout_at') DateTime? timeoutAt,
    @Default('pending') String status,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  const Transaction._();
}
