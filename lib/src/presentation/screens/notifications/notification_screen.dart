import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../domain/entities/notification.dart';
import '../../providers/notification_providers.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Notifications'),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
        suffixes: [
          if (unread > 0)
            FHeaderAction(
              icon: const Icon(FIcons.check),
              onPress: () async {
                final repo = ref.read(notificationRepositoryProvider);
                await repo.markAllAsRead();
              },
            ),
        ],
      ),
      child: notificationsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error loading notifications: $e',
              style: typo.sm.copyWith(color: colors.destructive),
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style:
                          typo.sm.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (unread > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FBadge(
                        child: Text('$unread unread'),
                      ),
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: () async {
                          final repo =
                              ref.read(notificationRepositoryProvider);
                          await repo.markAllAsRead();
                        },
                        child: const Text('Mark all as read'),
                      ),
                    ],
                  ),
                ),
              FTileGroup(
                children: [
                  for (final n in notifications)
                    _notificationTile(context, ref, n, colors, typo),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  FTile _notificationTile(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    FColors colors,
    FTypography typo,
  ) {
    final summary = _buildSummary(notification);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return FTile(
      title: Text(
        _typeLabel(notification.type),
        style: typo.sm.copyWith(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
          color: colors.foreground,
        ),
      ),
      subtitle: Text(
        summary,
        style: typo.xs.copyWith(color: colors.mutedForeground),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      prefix: Icon(
        _typeIcon(notification.type),
        color: notification.read ? colors.mutedForeground : colors.primary,
      ),
      details: Text(
        timeAgo,
        style: typo.xs.copyWith(color: colors.mutedForeground),
      ),
      suffix: notification.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
      onPress: () async {
        if (!notification.read) {
          final repo = ref.read(notificationRepositoryProvider);
          await repo.markAsRead(notification.id);
        }
      },
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'payment_request':
        return 'Payment Request';
      case 'payment_confirmed':
        return 'Payment Confirmed';
      case 'payment_rejected':
        return 'Payment Rejected';
      case 'transaction_added':
        return 'New Transaction';
      case 'group_invite':
        return 'Group Invite';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'payment_request':
        return Icons.payment;
      case 'payment_confirmed':
        return Icons.check_circle_outline;
      case 'payment_rejected':
        return Icons.cancel_outlined;
      case 'transaction_added':
        return Icons.receipt_long;
      case 'group_invite':
        return Icons.group_add;
      default:
        return Icons.notifications;
    }
  }

  String _buildSummary(AppNotification notification) {
    final payload = notification.payload;
    if (payload == null) return notification.type;
    final message = payload['message'] as String?;
    if (message != null) return message;
    final amount = payload['amount'];
    final from = payload['from_name'] ?? payload['from'];
    if (amount != null && from != null) {
      return '$from - ETB $amount';
    }
    return notification.type.replaceAll('_', ' ');
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
