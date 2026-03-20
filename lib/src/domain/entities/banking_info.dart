import 'package:freezed_annotation/freezed_annotation.dart';

part 'banking_info.freezed.dart';
part 'banking_info.g.dart';

@freezed
class BankingInfo with _$BankingInfo {
  const factory BankingInfo({
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? branch,
    String? swiftCode,
  }) = _BankingInfo;

  factory BankingInfo.fromJson(Map<String, dynamic> json) =>
      _$BankingInfoFromJson(json);
}
