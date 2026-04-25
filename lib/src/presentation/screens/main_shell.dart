import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/home_screen.dart';
import 'groups/groups_screen.dart';
import 'personal/personal_screen.dart';
import 'stats/stats_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    GroupsScreen(),
    PersonalScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(child: _screens[_index]),
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
                _buildNavItem(0, 'Home', FIcons.house, colors),
                _buildDivider(colors),
                _buildNavItem(1, 'Groups', FIcons.users, colors),
                _buildDivider(colors),
                _buildNavItem(2, 'Personal', FIcons.wallet, colors),
                _buildDivider(colors),
                _buildNavItem(3, 'Stats', FIcons.chartPie, colors),
                _buildDivider(colors),
                _buildNavItem(4, 'Settings', FIcons.settings, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(FColors colors) {
    return Container(
      width: 1.5,
      height: double.infinity,
      color: colors.foreground,
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, FColors colors) {
    final isSelected = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
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
