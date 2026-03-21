class AppNotification {
  final String id;
  final String userId;
  final String type;
  final Map<String, dynamic>? payload;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.payload,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        payload: json['payload'] != null
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : null,
        read: json['read'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'payload': payload,
        'read': read,
        'created_at': createdAt?.toIso8601String(),
      };
}
