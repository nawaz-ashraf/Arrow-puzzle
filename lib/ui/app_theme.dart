import 'package:flutter/material.dart';
import '../models/level_model.dart';

// ── Stitch Core Palette constants ──────────────────────────────────────────

/// Deep Teal — primary structural colour.
const kDeepTeal = Color(0xFF006D77);

/// Energetic Orange — interactive arrows, CTAs, success states.
const kEnergeticOrange = Color(0xFFFF8200);

/// Accent Teal — softer teal for decorative / inactive states.
const kAccentTeal = Color(0xFF83C5BE);

/// Soft White — primary canvas, reduces eye strain.
const kSoftWhite = Color(0xFFEDF6F9);

// ──────────────────────────────────────────────────────────────────────────

/// Encapsulates a full colour scheme for one game chapter theme.
class AppColorScheme {
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color primary;
  final Color accent;
  final Color accentAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color blockerColor;
  final Color linkedGlow;
  final Color hintGlow;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Brightness brightness;

  const AppColorScheme({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.primary,
    required this.accent,
    required this.accentAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.blockerColor,
    required this.linkedGlow,
    required this.hintGlow,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.brightness,
  });

  // Convenience helpers
  Color get primaryLight => primary.withValues(alpha: 0.15);
  Color get accentLight => accent.withValues(alpha: 0.15);
}

/// Central theme provider for the Arrow Puzzle game.
///
/// Returns a [AppColorScheme] for each [GameChapter], enabling the entire UI
/// to react to chapter changes driven by the current level.
class AppTheme {
  AppTheme._();

  // ── Chapter I — "Soft Tactile" (levels 1–10) ─────────────────────────────
  static const softTactile = AppColorScheme(
    background: kSoftWhite,           // #EDF6F9
    backgroundAlt: Color(0xFFD8E2E6),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE6EFF2),
    border: Color(0xFFBEC8CA),
    primary: kDeepTeal,               // #006D77
    accent: kEnergeticOrange,         // #FF8200
    accentAlt: kAccentTeal,           // #83C5BE
    textPrimary: Color(0xFF141D1F),
    textSecondary: Color(0xFF3E494A),
    blockerColor: Color(0xFF4A5568),
    linkedGlow: Color(0xFF9B59B6),
    hintGlow: kEnergeticOrange,
    successColor: Color(0xFF2ECC71),
    warningColor: Color(0xFFF39C12),
    errorColor: Color(0xFFE74C3C),
    brightness: Brightness.light,
  );

  // ── Chapter II — "Neon Dark" (levels 11–30) ───────────────────────────────
  static const neonDark = AppColorScheme(
    background: Color(0xFF0D1117),
    backgroundAlt: Color(0xFF161B22),
    surface: Color(0xFF1C2128),
    surfaceHigh: Color(0xFF21262D),
    border: Color(0xFF30363D),
    primary: Color(0xFF00B4C5),       // brighter teal for dark bg
    accent: kEnergeticOrange,         // #FF8200
    accentAlt: kAccentTeal,
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFF8B949E),
    blockerColor: Color(0xFF3D444D),
    linkedGlow: Color(0xFFBD93F9),    // purple glow on dark
    hintGlow: kEnergeticOrange,
    successColor: Color(0xFF3FB950),
    warningColor: Color(0xFFD29922),
    errorColor: Color(0xFFF85149),
    brightness: Brightness.dark,
  );

  // ── Chapter III — "Gold Elite" (levels 31+) ───────────────────────────────
  static const goldElite = AppColorScheme(
    background: Color(0xFF0A0A0F),
    backgroundAlt: Color(0xFF12121A),
    surface: Color(0xFF1A1A25),
    surfaceHigh: Color(0xFF22223A),
    border: Color(0xFF2D2D50),
    primary: Color(0xFF00B4C5),
    accent: Color(0xFFFFD700),        // Gold for elite chapter
    accentAlt: Color(0xFFFF8200),
    textPrimary: Color(0xFFF0E6D3),
    textSecondary: Color(0xFF9B8B6E),
    blockerColor: Color(0xFF2D2D50),
    linkedGlow: Color(0xFFFFD700),    // gold glow for linked pairs
    hintGlow: Color(0xFFFFD700),
    successColor: Color(0xFF50C878),
    warningColor: Color(0xFFFFD700),
    errorColor: Color(0xFFFF6B6B),
    brightness: Brightness.dark,
  );

  // ── Chapter VI — "Void Abyss" (levels 151–200) ───────────────────────────
  static const voidAbyss = AppColorScheme(
    background: Color(0xFF0B0014),
    backgroundAlt: Color(0xFF12001F),
    surface: Color(0xFF1A0A2E),
    surfaceHigh: Color(0xFF251440),
    border: Color(0xFF3D1D6B),
    primary: Color(0xFFBB86FC),       // Vibrant purple
    accent: Color(0xFFE040FB),        // Magenta accent
    accentAlt: Color(0xFF7C4DFF),
    textPrimary: Color(0xFFF3E5F5),
    textSecondary: Color(0xFF9575CD),
    blockerColor: Color(0xFF3D1D6B),
    linkedGlow: Color(0xFFE040FB),
    hintGlow: Color(0xFFBB86FC),
    successColor: Color(0xFF69F0AE),
    warningColor: Color(0xFFFFAB40),
    errorColor: Color(0xFFFF5252),
    brightness: Brightness.dark,
  );

  // ── Chapter VII — "Inferno Core" (levels 201–250) ─────────────────────────
  static const infernoCore = AppColorScheme(
    background: Color(0xFF140000),
    backgroundAlt: Color(0xFF1F0505),
    surface: Color(0xFF2A0A0A),
    surfaceHigh: Color(0xFF3D1515),
    border: Color(0xFF5C1A1A),
    primary: Color(0xFFFF6B6B),       // Fiery red
    accent: Color(0xFFFF4444),        // Crimson accent
    accentAlt: Color(0xFFFF8A65),
    textPrimary: Color(0xFFFFF0F0),
    textSecondary: Color(0xFFCC7777),
    blockerColor: Color(0xFF5C1A1A),
    linkedGlow: Color(0xFFFF4444),
    hintGlow: Color(0xFFFF6B6B),
    successColor: Color(0xFF81C784),
    warningColor: Color(0xFFFFCA28),
    errorColor: Color(0xFFFF1744),
    brightness: Brightness.dark,
  );

  // ── Chapter VIII — "Emerald Mythic" (levels 251–300) ──────────────────────
  static const emeraldMythic = AppColorScheme(
    background: Color(0xFF001A0A),
    backgroundAlt: Color(0xFF002410),
    surface: Color(0xFF0A3018),
    surfaceHigh: Color(0xFF144025),
    border: Color(0xFF1B5E20),
    primary: Color(0xFF00E676),       // Emerald green
    accent: Color(0xFF76FF03),        // Lime accent
    accentAlt: Color(0xFF00BFA5),
    textPrimary: Color(0xFFE8F5E9),
    textSecondary: Color(0xFF81C784),
    blockerColor: Color(0xFF1B5E20),
    linkedGlow: Color(0xFF76FF03),
    hintGlow: Color(0xFF00E676),
    successColor: Color(0xFF00E676),
    warningColor: Color(0xFFFFD740),
    errorColor: Color(0xFFFF5252),
    brightness: Brightness.dark,
  );

  /// Returns the correct [AppColorScheme] for a given [GameChapter].
  static AppColorScheme forChapter(GameChapter chapter) {
    switch (chapter) {
      case GameChapter.beginner:
        return softTactile;
      case GameChapter.easy:
      case GameChapter.medium:
        return neonDark;
      case GameChapter.hard:
      case GameChapter.expert:
        return goldElite;
      case GameChapter.master:
        return voidAbyss;
      case GameChapter.legend:
        return infernoCore;
      case GameChapter.mythic:
        return emeraldMythic;
    }
  }

  /// Convenience: derive chapter from level ID.
  static AppColorScheme forLevel(int levelId) {
    if (levelId <= 10)  return softTactile;
    if (levelId <= 50)  return neonDark;
    if (levelId <= 150) return goldElite;
    if (levelId <= 200) return voidAbyss;
    if (levelId <= 250) return infernoCore;
    return emeraldMythic;
  }

  /// Returns a [ThemeData] compatible with the current colour scheme.
  static ThemeData materialTheme(AppColorScheme cs) {
    return ThemeData(
      brightness: cs.brightness,
      colorScheme: ColorScheme(
        brightness: cs.brightness,
        primary: cs.primary,
        onPrimary: Colors.white,
        secondary: cs.accent,
        onSecondary: Colors.white,
        error: cs.errorColor,
        onError: Colors.white,
        surface: cs.surface,
        onSurface: cs.textPrimary,
      ),
      scaffoldBackgroundColor: cs.background,
      fontFamily: 'PlusJakartaSans',
      useMaterial3: true,
      cardColor: cs.surface,
      dividerColor: cs.border,
    );
  }
}
