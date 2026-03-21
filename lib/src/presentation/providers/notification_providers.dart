import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/notification.dart';
import 'auth_providers.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationRepository(client);
});

final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications();
});

final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.whenOrNull(
        data: (notifications) =>
            notifications.where((n) => !n.read).length,
      ) ??
      0;
});
