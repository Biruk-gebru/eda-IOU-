import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/notification.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<AppNotification>> getNotifications() async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  Stream<List<AppNotification>> watchNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => AppNotification.fromJson(e)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', _userId)
        .eq('read', false);
  }

  Future<int> getUnreadCount() async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .eq('read', false);
    return (data as List).length;
  }
}
