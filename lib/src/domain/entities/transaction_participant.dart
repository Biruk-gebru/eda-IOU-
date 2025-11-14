import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_participant.freezed.dart';


@freezed
class TransactionParticipant with _$TransactionParticipant {
  const factory TransactionParticipant({
    required String id,
    required String transactionId,
    required String userId,
    required double amountDue,
    bool? approved,
    DateTime? approvedAt,
  }) = _TransactionParticipant;

  const TransactionParticipant._();
}