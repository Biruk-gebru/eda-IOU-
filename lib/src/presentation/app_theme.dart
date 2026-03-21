import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Tonal Slots ──────────────────────────────────────────────────────────────
// Dark  : bg #111318 → card #1C2030 → raised #252B3B → border #2D3348
// Light : bg #F5F7FA → card #FFFFFF → raised #F0F2F5 → border #DDE2EC
// All cards are the SAME tonal color — separation via border, shadow & spacing.
// Primary accent is slate-300 (dark) / slate-700 (light) — no purple, no color.
// ─────────────────────────────────────────────────────────────────────────────

const _darkBg = Color(0xFF111318);
const _darkCard = Color(0xFF1C2030);
const _darkRaised = Color(0xFF252B3B);
const _darkBorder = Color(0xFF2D3348);
const _darkFg = Color(0xFFE2E8F0);
const _darkMutedFg = Color(0xFF64748B);
const _darkPrimary = Color(0xFFCDD5E0);
const _darkPrimaryFg = Color(0xFF1C2030);
const _darkDestructive = Color(0xFFF87171);
const _darkDestructiveFg = Color(0xFF1C2030);

const _lightBg = Color(0xFFF5F7FA);
const _lightCard = Color(0xFFFFFFFF);
const _lightBorder = Color(0xFFDDE2EC);
const _lightFg = Color(0xFF0F1117);
const _lightMutedFg = Color(0xFF64748B);
const _lightPrimary = Color(0xFF334155);
const _lightPrimaryFg = Color(0xFFFFFFFF);
const _lightMuted = Color(0xFFF0F2F5);
const _lightDestructive = Color(0xFFDC2626);
const _lightDestructiveFg = Color(0xFFFFFFFF);

/// Returns a [FThemeData] with the EDA monochromatic palette and Google Fonts.
FThemeData buildFTheme({required bool isDark}) {
  // Start from the touch-optimised base (FPlatformThemeData → FThemeData)
  final FThemeData base = isDark ? FThemes.zinc.dark.touch : FThemes.zinc.light.touch;

  // Override only colors; typography we rebuild as a new FThemeData.
  final colors = isDark
      ? base.colors.copyWith(
          background: _darkBg,
          foreground: _darkFg,
          card: _darkCard,
          primary: _darkPrimary,
          primaryForeground: _darkPrimaryFg,
          secondary: _darkRaised,
          secondaryForeground: _darkFg,
          muted: _darkRaised,
          mutedForeground: _darkMutedFg,
          border: _darkBorder,
          destructive: _darkDestructive,
          destructiveForeground: _darkDestructiveFg,
        )
      : base.colors.copyWith(
          background: _lightBg,
          foreground: _lightFg,
          card: _lightCard,
          primary: _lightPrimary,
          primaryForeground: _lightPrimaryFg,
          secondary: _lightMuted,
          secondaryForeground: _lightFg,
          muted: _lightMuted,
          mutedForeground: _lightMutedFg,
          border: _lightBorder,
          destructive: _lightDestructive,
          destructiveForeground: _lightDestructiveFg,
        );

  // Rebuild with updated colors (typography will be re-inherited from colors).
  // We also inject Google Fonts via the typography's defaultFontFamily.
  final typo = base.typography.copyWith(
    xs2: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400),
    xs: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
    sm: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
    md: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400),
    lg: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
    xl: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700),
    xl2: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700),
    xl3: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w700),
    xl4: GoogleFonts.outfit(fontSize: 44, fontWeight: FontWeight.w800),
  );

  // Build a brand-new FThemeData that inherits all widget styles from the
  // new colors. This is the cleanest way to apply a palette change in forui.
  return FThemeData(
    colors: colors,
    touch: isDark, // touch=true for dark (mobile target)
    typography: typo,
  );
}
