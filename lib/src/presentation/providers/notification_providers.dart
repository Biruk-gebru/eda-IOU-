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
    StreamProvider<List<AppNotification>>((ref) async* {
  final repository = ref.watch(notificationRepositoryProvider);
  try {
    await for (final list in repository.watchNotifications()) {
      yield list;
    }
  } on Exception {
    // Realtime subscription failed (e.g. expired JWT) — fall back to REST fetch.
    // The user can pull-to-refresh to re-establish the realtime connection.
    yield await repository.getNotifications();
  }
});

final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.whenOrNull(
        data: (notifications) =>
            notifications.where((n) => !n.read).length,
      ) ??
      0;
});
