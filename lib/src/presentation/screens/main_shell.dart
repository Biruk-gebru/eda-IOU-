import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/notification.dart';
import '../../core/services/local_notification_service.dart';
import '../providers/notification_providers.dart';
import '../providers/shell_provider.dart';
import 'home/home_screen.dart';
import 'groups/groups_screen.dart';
import 'personal/personal_screen.dart';
import 'stats/stats_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _screens = const [
    HomeScreen(),
    GroupsScreen(),
    PersonalScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  final Set<String> _knownNotificationIds = {};
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    LocalNotificationService.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final index = ref.watch(shellTabProvider);

    ref.listen<AsyncValue<List<AppNotification>>>(notificationsProvider, (_, next) {
      next.whenData((notifications) {
        if (!_notificationsInitialized) {
          _knownNotificationIds.addAll(notifications.map((n) => n.id));
          _notificationsInitialized = true;
          return;
        }
        for (final n in notifications) {
          if (!_knownNotificationIds.contains(n.id)) {
            _knownNotificationIds.add(n.id);
            if (!n.read) LocalNotificationService.show(n);
          }
        }
      });
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(child: _screens[index]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(top: BorderSide(color: colors.foreground, width: 1.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _navItem(0, 'Home', FIcons.house, colors, index),
                _divider(colors),
                _navItem(1, 'Groups', FIcons.users, colors, index),
                _divider(colors),
                _navItem(2, 'Personal', FIcons.wallet, colors, index),
                _divider(colors),
                _navItem(3, 'Stats', FIcons.chartPie, colors, index),
                _divider(colors),
                _navItem(4, 'Settings', FIcons.settings, colors, index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(FColors colors) => Container(
        width: 1.5,
        height: double.infinity,
        color: colors.foreground,
      );

  Widget _navItem(int idx, String label, IconData icon, FColors colors, int current) {
    final isSelected = current == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(shellTabProvider.notifier).state = idx,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isSelected ? colors.primary : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? colors.foreground : colors.mutedForeground,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.foreground : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
