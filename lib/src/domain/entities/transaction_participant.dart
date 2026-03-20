import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_participant.freezed.dart';
part 'transaction_participant.g.dart';

@freezed
class TransactionParticipant with _$TransactionParticipant {
  const factory TransactionParticipant({
    required String id,
    @JsonKey(name: 'transaction_id') required String transactionId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'amount_due') required double amountDue,
    bool? approved,
    @JsonKey(name: 'approved_at') DateTime? approvedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TransactionParticipant;

  factory TransactionParticipant.fromJson(Map<String, dynamic> json) =>
      _$TransactionParticipantFromJson(json);

  const TransactionParticipant._();
}
