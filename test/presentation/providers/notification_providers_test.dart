import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eda/src/data/repositories/notification_repository.dart';
import 'package:eda/src/domain/entities/notification.dart';
import 'package:eda/src/presentation/providers/notification_providers.dart';
import '../../helpers/fixtures.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockNotificationRepository();
    container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  // ─── notificationsProvider ────────────────────────────────────────────────

  group('notificationsProvider', () {
    test('streams notifications from repository', () async {
      final controller = StreamController<List<AppNotification>>();
      when(() => mockRepo.watchNotifications())
          .thenAnswer((_) => controller.stream);

      final notifications = [
        makeNotification(id: 'n-1', read: false),
        makeNotification(id: 'n-2', read: true),
      ];
      controller.add(notifications);

      final result = await container.read(notificationsProvider.future);

      expect(result.length, 2);
      await controller.close();
    });

    test('returns empty list when stream emits empty', () async {
      final controller = StreamController<List<AppNotification>>();
      when(() => mockRepo.watchNotifications())
          .thenAnswer((_) => controller.stream);

      controller.add([]);

      final result = await container.read(notificationsProvider.future);

      expect(result, isEmpty);
      await controller.close();
    });
  });

  // ─── unreadCountProvider ──────────────────────────────────────────────────

  group('unreadCountProvider', () {
    test('counts only unread notifications', () async {
      final controller = StreamController<List<AppNotification>>();
      when(() => mockRepo.watchNotifications())
          .thenAnswer((_) => controller.stream);

      // Emit: 2 unread, 1 read
      controller.add([
        makeNotification(id: 'n-1', read: false),
        makeNotification(id: 'n-2', read: false),
        makeNotification(id: 'n-3', read: true),
      ]);

      // Let the stream propagate.
      await container.read(notificationsProvider.future);

      final count = container.read(unreadCountProvider);
      expect(count, 2);

      await controller.close();
    });

    test('returns 0 when all notifications are read', () async {
      final controller = StreamController<List<AppNotification>>();
      when(() => mockRepo.watchNotifications())
          .thenAnswer((_) => controller.stream);

      controller.add([
        makeNotification(id: 'n-1', read: true),
        makeNotification(id: 'n-2', read: true),
      ]);

      await container.read(notificationsProvider.future);

      expect(container.read(unreadCountProvider), 0);
      await controller.close();
    });

    test('returns 0 when stream has not emitted yet (loading state)', () {
      final controller = StreamController<List<AppNotification>>();
      when(() => mockRepo.watchNotifications())
          .thenAnswer((_) => controller.stream);

      // Do NOT emit anything — provider is still loading
      expect(container.read(unreadCountProvider), 0);

      controller.close();
    });

    test('returns 0 when notification list is empty', () async {
      final controller = StreamController<List<AppNotification>>();
      when(() => mockRepo.watchNotifications())
          .thenAnswer((_) => controller.stream);

      controller.add([]);
      await container.read(notificationsProvider.future);

      expect(container.read(unreadCountProvider), 0);
      await controller.close();
    });

    test('reflects correct count after second stream emission', () async {
      final controller = StreamController<List<AppNotification>>();
      when(() => mockRepo.watchNotifications())
          .thenAnswer((_) => controller.stream);

      // First emission: 3 unread
      controller.add([
        makeNotification(id: 'n-1', read: false),
        makeNotification(id: 'n-2', read: false),
        makeNotification(id: 'n-3', read: false),
      ]);
      await container.read(notificationsProvider.future);
      expect(container.read(unreadCountProvider), 3);

      // Second emission: all read (e.g., user opened notification panel)
      controller.add([
        makeNotification(id: 'n-1', read: true),
        makeNotification(id: 'n-2', read: true),
        makeNotification(id: 'n-3', read: true),
      ]);
      // Allow stream event to propagate
      await Future<void>.delayed(Duration.zero);
      expect(container.read(unreadCountProvider), 0);

      await controller.close();
    });
  });
}
