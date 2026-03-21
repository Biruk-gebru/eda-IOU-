class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final DateTime? joinedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = 'member',
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        userId: json['user_id'] as String,
        role: json['role'] as String? ?? 'member',
        joinedAt: json['joined_at'] != null
            ? DateTime.parse(json['joined_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'user_id': userId,
        'role': role,
        'joined_at': joinedAt?.toIso8601String(),
      };
}
