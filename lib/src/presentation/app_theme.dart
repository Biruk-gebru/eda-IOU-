import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── EDA Neo-Brutalist Theme (Light) ─────────────────────────────────────────
// Paper  : #EFECDF (Warm cream background)
// Ink    : #16140F (Foreground, sharp 1.5px borders)
// Card   : #FBFAF3 (Slightly lighter surface)
// Accent : #D9A441 (Ochre)
// ─────────────────────────────────────────────────────────────────────────────
const _lightPaper = Color(0xFFF2EFEB);
const _lightInk = Color(0xFF161414);
const _lightCard = Color(0xFFFFFFFF);
const _lightAccent = Color(0xFF00D09E); // Bright Teal
const _lightMuted = Color(0xFF8D8A80);
const _lightBad = Color(0xFFE24C4B);

// ─── EDA Neo-Brutalist Theme (Dark) ──────────────────────────────────────────
// Paper  : #1A1A1A
// Ink    : #F2EFEB
// Card   : #262626
// Accent : #00D09E
// ─────────────────────────────────────────────────────────────────────────────
const _darkPaper = Color(0xFF1A1A1A);
const _darkInk = Color(0xFFF2EFEB);
const _darkCard = Color(0xFF262626);
const _darkAccent = Color(0xFF00D09E);
const _darkMuted = Color(0xFFA19E94);
const _darkBad = Color(0xFFE24C4B);

/// Returns a [FThemeData] with the EDA monochromatic palette and Google Fonts.
FThemeData buildFTheme({required bool isDark}) {
  final FThemeData base = isDark ? FThemes.zinc.dark.touch : FThemes.zinc.light.touch;

  final paper = isDark ? _darkPaper : _lightPaper;
  final ink = isDark ? _darkInk : _lightInk;
  final card = isDark ? _darkCard : _lightCard;
  final accent = isDark ? _darkAccent : _lightAccent;
  final muted = isDark ? _darkMuted : _lightMuted;
  final bad = isDark ? _darkBad : _lightBad;

  final colors = base.colors.copyWith(
    background: paper,
    foreground: ink,
    card: card,
    primary: accent,
    primaryForeground: _lightInk, // Keep dark ink for text on primary ochre buttons
    secondary: card,
    secondaryForeground: ink,
    muted: card,
    mutedForeground: muted,
    border: ink,
    destructive: bad,
    destructiveForeground: _lightPaper,
  );

  final typo = base.typography.copyWith(
    xs2: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400),
    xs: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
    sm: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
    md: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400),
    lg: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600),
    xl: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600),
    xl2: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w600),
    xl3: GoogleFonts.fraunces(fontSize: 34, fontWeight: FontWeight.w600),
    xl4: GoogleFonts.fraunces(fontSize: 44, fontWeight: FontWeight.w600),
  );

  return FThemeData(colors: colors, touch: true, typography: typo);
}
