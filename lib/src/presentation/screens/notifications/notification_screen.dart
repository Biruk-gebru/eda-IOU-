import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/notification.dart';
import '../../providers/notification_providers.dart';
import '../../providers/shell_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: colors.background, // Paper background
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.foreground, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '←',
                        style: typo.lg.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: typo.lg.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    GestureDetector(
                      onTap: () async {
                        final repo = ref.read(notificationRepositoryProvider);
                        await repo.markAllAsRead();
                        ref.invalidate(notificationsProvider);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.foreground, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Icon(FIcons.check, size: 16, color: colors.foreground),
                      ),
                    ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationsProvider);
                  await ref
                      .read(notificationsProvider.future)
                      .catchError((_) => <AppNotification>[]);
                },
                child: notificationsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                  error: (_, __) => LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colors.foreground, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(FIcons.wifiOff, size: 30, color: colors.foreground),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Connection issue',
                                  style: typo.lg.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colors.foreground,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pull down to retry',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) => ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: constraints.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colors.foreground, width: 1.5),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(FIcons.bell, size: 30, color: colors.foreground),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'No notifications yet',
                                      style: typo.lg.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: colors.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                      children: [
                        if (unread > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    border: Border.all(color: colors.foreground, width: 1.5),
                                  ),
                                  child: Text(
                                    '$unread unread',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.foreground,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final repo = ref.read(notificationRepositoryProvider);
                                    await repo.markAllAsRead();
                                    ref.invalidate(notificationsProvider);
                                  },
                                  child: Text(
                                    'Mark all as read',
                                    style: typo.sm.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.card,
                            border: Border.all(color: colors.foreground, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < notifications.length; i++)
                                _notificationTile(context, ref, notifications[i], colors, typo, i == 0),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    FColors colors,
    FTypography typo,
    bool isFirst,
  ) {
    final summary = _buildSummary(notification);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return GestureDetector(
      onTap: () async {
        if (!notification.read) {
          await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          ref.invalidate(notificationsProvider);
        }
        if (!context.mounted) return;
        _navigateTo(context, ref, notification.type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? Colors.transparent : colors.primary.withValues(alpha: 0.1),
          border: isFirst ? null : Border(top: BorderSide(color: colors.foreground, width: 1.0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: colors.foreground, width: 1.5),
                color: notification.read ? colors.card : colors.primary,
              ),
              alignment: Alignment.center,
              child: Icon(
                _typeIcon(notification.type),
                size: 20,
                color: notification.read ? colors.foreground : colors.background,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _typeLabel(notification.type),
                          style: typo.sm.copyWith(
                            fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.mutedForeground,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notification.read) ...[
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: colors.primary,
                  border: Border.all(color: colors.foreground, width: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, WidgetRef ref, String type) {
    final tab = switch (type) {
      'group_invitation' => 1,
      'payment_request' || 'payment_confirmed' || 'payment_rejected' => 2,
      _ => 0,
    };
    ref.read(shellTabProvider.notifier).state = tab;
    Navigator.of(context).pop();
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
        return Icons.request_quote_outlined;
      case 'payment_confirmed':
        return Icons.check_circle_outline;
      case 'payment_rejected':
        return Icons.cancel_outlined;
      case 'transaction_added':
        return Icons.receipt_outlined;
      case 'group_invite':
        return Icons.person_add_outlined;
      default:
        return Icons.notifications_none;
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
