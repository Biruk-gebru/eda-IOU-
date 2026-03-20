import 'package:freezed_annotation/freezed_annotation.dart';

part 'net_balance.freezed.dart';
part 'net_balance.g.dart';

@freezed
class NetBalance with _$NetBalance {
  const factory NetBalance({
    required String id,
    @JsonKey(name: 'user_a') required String userA,
    @JsonKey(name: 'user_b') required String userB,
    @JsonKey(name: 'net_amount') required double netAmount,
    @JsonKey(name: 'last_updated') DateTime? lastUpdated,
  }) = _NetBalance;

  factory NetBalance.fromJson(Map<String, dynamic> json) =>
      _$NetBalanceFromJson(json);

  const NetBalance._();
}
