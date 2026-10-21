import 'package:flutter/material.dart';

/// HomeSafe design tokens.
/// Calm and trustworthy: deep teal on soft neutral surfaces, white cards,
/// one bold red reserved for emergencies and "urgent" results.
/// TODO(team): final brand colours and logo.
const brandTeal = Color(0xFF0E6E7E);
const fontFamily = 'NotoSans';

/// Emergency red. Used ONLY for the emergency button/screen and red results.
const emergencyRed = Color(0xFFC62828);
const emergencyOnRed = Colors.white;

const levelRedColor = Color(0xFFC62828);
const levelAmberColor = Color(0xFFB45F06); // Dark amber: readable with white text.
const levelGreenColor = Color(0xFF2E7D32);

/// Minimum tap target. The brief asks for 48; main buttons use 56.
const minTap = 56.0;
const radiusLarge = 20.0;
const radiusMedium = 14.0;

/// Soft background + strong foreground for a level (badges, banners).
({Color soft, Color strong, Color onSoft}) levelPalette(String level, Brightness b) {
  final dark = b == Brightness.dark;
  return switch (level) {
    'red' => (soft: dark ? const Color(0xFF4A1515) : const Color(0xFFFDE7E7), strong: levelRedColor, onSoft: dark ? const Color(0xFFFFB4AB) : const Color(0xFF8C1D18)),
    'amber' => (soft: dark ? const Color(0xFF4A3008) : const Color(0xFFFFF0D9), strong: levelAmberColor, onSoft: dark ? const Color(0xFFFFCC80) : const Color(0xFF7A3E00)),
    _ => (soft: dark ? const Color(0xFF173A1B) : const Color(0xFFE5F4E6), strong: levelGreenColor, onSoft: dark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20)),
  };
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seeded = ColorScheme.fromSeed(seedColor: brandTeal, brightness: brightness);
  final scheme = seeded.copyWith(
    primary: dark ? const Color(0xFF7DD3E0) : brandTeal,
    onPrimary: dark ? const Color(0xFF00363F) : Colors.white,
    primaryContainer: dark ? const Color(0xFF0B4F5B) : const Color(0xFFD5EFF2),
    onPrimaryContainer: dark ? const Color(0xFFCDEFF4) : const Color(0xFF033640),
    tertiaryContainer: dark ? const Color(0xFF4A3B12) : const Color(0xFFFFF2D6),
    onTertiaryContainer: dark ? const Color(0xFFFFE0A3) : const Color(0xFF4A3300),
    surface: dark ? const Color(0xFF0F1517) : const Color(0xFFF4F7F7),
    surfaceContainerLowest: dark ? const Color(0xFF151C1E) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF192123) : const Color(0xFFEEF3F3),
    surfaceContainer: dark ? const Color(0xFF1D2628) : const Color(0xFFE8EEEE),
    outlineVariant: dark ? const Color(0xFF2B3638) : const Color(0xFFDCE4E5),
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: fontFamily);
  final t = base.textTheme;
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium));
  const buttonText = TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w700);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    textTheme: t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.2),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 17),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 17, height: 1.45),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(minTap, minTap),
        shape: buttonShape,
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(minTap, minTap),
        shape: buttonShape,
        textStyle: buttonText,
        side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    // Explicit colours: the defaults made unselected labels too faint in dark mode.
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      side: BorderSide(color: scheme.outlineVariant, width: 1.5),
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      minVerticalPadding: 12,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primaryContainer,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(8),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      ),
    ),
  );
}
