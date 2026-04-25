import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/notification.dart';
import '../../presentation/providers/shell_provider.dart';

/// Top-level callback required by flutter_local_notifications for background
/// notification taps (must be a top-level or static function with this pragma).
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  LocalNotificationService._handleResponse(response);
}

class LocalNotificationService {
  LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const _storage = FlutterSecureStorage();
  static const _prefKey = 'push_notifications_enabled';

  static const _channelId = 'eda_main';
  static const _channelName = 'EDA';

  static Future<bool> isEnabled() async {
    final v = await _storage.read(key: _prefKey);
    return v != 'false';
  }

  static Future<void> setEnabled(bool value) async {
    await _storage.write(key: _prefKey, value: value.toString());
  }

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );
  }

  /// Request OS-level permission. Call once after the user has logged in.
  static Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Show a system notification for [n]. No-op if the user has disabled push.
  static Future<void> show(AppNotification n) async {
    if (!await isEnabled()) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      // hashCode can be negative; mask to a non-negative int32
      n.id.hashCode & 0x7FFFFFFF,
      _title(n.type),
      _body(n),
      details,
      payload: jsonEncode({'type': n.type, 'payload': n.payload}),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _title(String type) => switch (type) {
        'group_invitation' => 'Group Invitation',
        'payment_request' => 'Payment Request',
        'payment_confirmed' => 'Payment Confirmed',
        'payment_rejected' => 'Payment Rejected',
        'transaction_added' => 'New Transaction',
        _ => 'EDA',
      };

  static String _body(AppNotification n) {
    final p = n.payload;
    if (p == null) return n.type.replaceAll('_', ' ');
    return switch (n.type) {
      'group_invitation' =>
        "You've been invited to join ${p['group_name'] ?? 'a group'}",
      'payment_request' =>
        'New payment request for ETB ${p['amount'] ?? ''}',
      'payment_confirmed' => 'Your payment was confirmed',
      'payment_rejected' => 'Your payment was rejected',
      'transaction_added' => 'A new transaction was added',
      _ => p['message'] as String? ?? n.type.replaceAll('_', ' '),
    };
  }

  @pragma('vm:entry-point')
  static void _handleResponse(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigate(
        data['type'] as String?,
        data['payload'] as Map<String, dynamic>?,
      );
    } catch (_) {}
  }

  static void _navigate(String? type, Map<String, dynamic>? payload) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Map notification type → shell tab index
    final tab = switch (type) {
      'group_invitation' => 1,                                    // Groups
      'payment_request' || 'payment_confirmed' ||
      'payment_rejected' => 2,                                    // Personal
      _ => 0,                                                     // Home
    };

    // Switch the bottom-nav tab
    ProviderScope.containerOf(context, listen: false)
        .read(shellTabProvider.notifier)
        .state = tab;
  }
}
