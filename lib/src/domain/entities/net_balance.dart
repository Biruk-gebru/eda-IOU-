import 'package:freezed_annotation/freezed_annotation.dart';

part 'net_balance.freezed.dart';


@freezed
class NetBalance with _$NetBalance {
  const factory NetBalance({
    required String id,
    required String userIdA,
    required String userIdB,
    required double netAmount,
    required DateTime lastUpdated,
  }) = _NetBalance;

    const NetBalance._();
}