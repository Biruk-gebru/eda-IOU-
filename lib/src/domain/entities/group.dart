import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';


@freezed
class Group with _$Group {
  const factory Group({
    required String id,
    required String name,
    required String description,
    required String creatorId,
    required String joinMode,
    required DateTime createdAt,
  }) = _Group;

  const Group._();
}