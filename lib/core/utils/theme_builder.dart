import 'package:flutter/material.dart';

import '../constants/background_colors.dart';

/// Builds the app's [ThemeData] for one brightness: [accentColor] always
/// drives primary/secondary/tertiary via Material's seed algorithm, and
/// [background] optionally overrides just the surface tones — the two
/// are independent, since there's no way to derive "a custom background"
/// from an accent seed the way light/dark variants of an accent are
/// derived.
ThemeData buildAppTheme({
  required Color accentColor,
  required Brightness brightness,
  required BackgroundOption background,
}) {
  var colorScheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: brightness,
  );

  final customSurface = brightness == Brightness.dark
      ? background.dark
      : background.light;
  if (customSurface != null) {
    colorScheme = _withCustomSurface(colorScheme, customSurface, brightness);
  }

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

/// Derives a small set of consistent surface tones from a single chosen
/// color, rather than hand-picking six shades per preset: in dark mode
/// each higher "elevation" level gets a little lighter (Material's own
/// convention — elevated surfaces catch more light); in light mode they
/// get a little darker, since [surface] here can be a flat white/black
/// with no built-in tonal palette to draw the rest from.
ColorScheme _withCustomSurface(
  ColorScheme base,
  Color surface,
  Brightness brightness,
) {
  final isDark = brightness == Brightness.dark;
  final hsl = HSLColor.fromColor(surface);

  Color shade(double delta) {
    final lightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  final step = isDark ? 0.035 : -0.025;

  return base.copyWith(
    surface: surface,
    surfaceContainerLowest: shade(isDark ? -0.02 : 0.015),
    surfaceContainerLow: shade(step),
    surfaceContainer: shade(step * 2),
    surfaceContainerHigh: shade(step * 3),
    surfaceContainerHighest: shade(step * 4),
    onSurface: isDark ? Colors.white : Colors.black87,
    onSurfaceVariant: isDark ? Colors.white70 : Colors.black54,
  );
}
