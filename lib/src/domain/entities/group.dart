class Group {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final String joinMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    this.joinMode = 'invite',
    this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        creatorId: json['creator_id'] as String,
        joinMode: json['join_mode'] as String? ?? 'invite',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'creator_id': creatorId,
        'join_mode': joinMode,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
