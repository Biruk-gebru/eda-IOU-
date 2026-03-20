import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'home/home_screen.dart';
import 'groups/groups_screen.dart';
import 'personal/personal_screen.dart';
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
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => FScaffold(
        footer: FBottomNavigationBar(
          index: _index,
          onChange: (i) => setState(() => _index = i),
          children: const [
            FBottomNavigationBarItem(
              icon: Icon(FIcons.house),
              label: Text('Home'),
            ),
            FBottomNavigationBarItem(
              icon: Icon(FIcons.users),
              label: Text('Groups'),
            ),
            FBottomNavigationBarItem(
              icon: Icon(FIcons.wallet),
              label: Text('Personal'),
            ),
            FBottomNavigationBarItem(
              icon: Icon(FIcons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        child: _screens[_index],
      );
}
