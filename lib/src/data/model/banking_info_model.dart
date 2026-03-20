import 'package:hive/hive.dart';
import '../../domain/entities/banking_info.dart';

part 'banking_info_model.g.dart';

@HiveType(typeId: 0)
class BankingInfoModel extends HiveObject {
  @HiveField(0)
  final String bankName;

  @HiveField(1)
  final String accountName;

  @HiveField(2)
  final String accountNumber;

  @HiveField(3)
  final String? branch;

  @HiveField(4)
  final String? swiftCode;

  BankingInfoModel({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.branch,
    this.swiftCode,
  });

  factory BankingInfoModel.fromEntity(BankingInfo entity) {
    return BankingInfoModel(
      bankName: entity.bankName,
      accountName: entity.accountName,
      accountNumber: entity.accountNumber,
      branch: entity.branch,
      swiftCode: entity.swiftCode,
    );
  }

  BankingInfo toEntity() {
    return BankingInfo(
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
      branch: branch,
      swiftCode: swiftCode,
    );
  }
}
