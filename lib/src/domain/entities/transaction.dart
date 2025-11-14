import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';


@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    @Default(null) String? groupId,
    required String description,
    required String creatorId,
    required String payerId,
    required double totalAmount,
    required String currency,
    @Default(null) Map<String, dynamic>? metadata,
    required DateTime createdAt,
    required DateTime timeoutAt,
    required String status,
  }) = _Transaction;

  const Transaction._();
}