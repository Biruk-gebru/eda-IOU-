import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../app_theme.dart';

enum AppThemeMode { system, light, dark }

final themeModeProvider =
    StateProvider<AppThemeMode>((ref) => AppThemeMode.system);

FThemeData resolveTheme(AppThemeMode mode, Brightness platformBrightness) {
  final isDark = switch (mode) {
    AppThemeMode.dark => true,
    AppThemeMode.light => false,
    AppThemeMode.system => platformBrightness == Brightness.dark,
  };
  return buildFTheme(isDark: isDark);
}
