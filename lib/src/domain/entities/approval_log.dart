import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_log.freezed.dart';
part 'approval_log.g.dart';

@freezed
class ApprovalLog with _$ApprovalLog {
  const factory ApprovalLog({
    required String id,
    @JsonKey(name: 'transaction_id') required String transactionId,
    @JsonKey(name: 'user_id') required String userId,
    required String action,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ApprovalLog;

  factory ApprovalLog.fromJson(Map<String, dynamic> json) =>
      _$ApprovalLogFromJson(json);

  const ApprovalLog._();
}
