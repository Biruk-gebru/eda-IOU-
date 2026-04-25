import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── EDA Neo-Brutalist Theme ──────────────────────────────────────────────────
// Paper  : #EFECDF (Warm cream background)
// Ink    : #16140F (Foreground, sharp 1.5px borders)
// Card   : #FBFAF3 (Slightly lighter surface)
// Accent : #D9A441 (Ochre)
// Good   : #1F6A3A
// Bad    : #9A2A1F
// Muted  : #7A7363
// ─────────────────────────────────────────────────────────────────────────────

const _edaPaper = Color(0xFFEFECDF);
const _edaInk = Color(0xFF16140F);
const _edaCard = Color(0xFFFBFAF3);
const _edaAccent = Color(0xFFD9A441);
const _edaMuted = Color(0xFF7A7363);
const _edaGood = Color(0xFF1F6A3A);
const _edaBad = Color(0xFF9A2A1F);

/// Returns a [FThemeData] with the EDA monochromatic palette and Google Fonts.
FThemeData buildFTheme({required bool isDark}) {
  // Use light base for the warm paper theme regardless of isDark for now
  // as the Neo-brutalist design is specifically paper-tinted.
  final FThemeData base = FThemes.zinc.light.touch;

  final colors = base.colors.copyWith(
    background: _edaPaper,
    foreground: _edaInk,
    card: _edaCard,
    primary: _edaAccent,
    primaryForeground: _edaInk,
    secondary: _edaCard, // Or maybe a soft ink
    secondaryForeground: _edaInk,
    muted: _edaCard,
    mutedForeground: _edaMuted,
    border: _edaInk,
    destructive: _edaBad,
    destructiveForeground: _edaPaper,
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
