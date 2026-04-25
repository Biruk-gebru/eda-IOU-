class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final String status;
  final String? invitedBy;
  final DateTime? joinedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = 'member',
    this.status = 'active',
    this.invitedBy,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        userId: json['user_id'] as String,
        role: json['role'] as String? ?? 'member',
        status: json['status'] as String? ?? 'active',
        invitedBy: json['invited_by'] as String?,
        joinedAt: json['joined_at'] != null
            ? DateTime.parse(json['joined_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'user_id': userId,
        'role': role,
        'status': status,
        'invited_by': invitedBy,
        'joined_at': joinedAt?.toIso8601String(),
      };
}
