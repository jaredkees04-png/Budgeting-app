import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/core/constants/background_colors.dart';
import 'package:budgeting_app/core/utils/theme_builder.dart';

void main() {
  const accent = Color(0xFF2E7D32);

  test('Default background leaves the seeded surface color untouched', () {
    final seeded = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark);
    final theme = buildAppTheme(
      accentColor: accent,
      brightness: Brightness.dark,
      background: kBackgroundOptions.first,
    );

    expect(theme.colorScheme.surface, seeded.surface);
  });

  test('A non-default background overrides surface but not accent colors', () {
    const option = BackgroundOption(
      name: 'Pure',
      light: Color(0xFFFFFFFF),
      dark: Color(0xFF000000),
    );
    final seeded = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark);
    final theme = buildAppTheme(
      accentColor: accent,
      brightness: Brightness.dark,
      background: option,
    );

    expect(theme.colorScheme.surface, const Color(0xFF000000));
    expect(theme.colorScheme.primary, seeded.primary,
        reason: 'Accent-derived colors should be unaffected by a background override');
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
  });

  test('Elevated surface containers get lighter in dark mode, darker in light mode', () {
    const darkOption = BackgroundOption(
      name: 'Cool Gray',
      light: Color(0xFFF1F2F4),
      dark: Color(0xFF17181A),
    );

    final darkTheme = buildAppTheme(
      accentColor: accent,
      brightness: Brightness.dark,
      background: darkOption,
    );
    expect(
      HSLColor.fromColor(darkTheme.colorScheme.surfaceContainerHighest).lightness,
      greaterThan(HSLColor.fromColor(darkTheme.colorScheme.surface).lightness),
    );

    final lightTheme = buildAppTheme(
      accentColor: accent,
      brightness: Brightness.light,
      background: darkOption,
    );
    expect(
      HSLColor.fromColor(lightTheme.colorScheme.surfaceContainerHighest).lightness,
      lessThan(HSLColor.fromColor(lightTheme.colorScheme.surface).lightness),
    );
  });
}
