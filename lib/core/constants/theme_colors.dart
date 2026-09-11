import 'package:flutter/material.dart';

class ThemeColorOption {
  final String name;
  final Color color;

  const ThemeColorOption({required this.name, required this.color});
}

/// Preset seed colors for the app-wide Material 3 color scheme. The
/// first entry is the app's original color, so a fresh install (and
/// anyone who never opens Settings) looks exactly as before.
const List<ThemeColorOption> kThemeColorOptions = [
  ThemeColorOption(name: 'Green', color: Color(0xFF2E7D32)),
  ThemeColorOption(name: 'Teal', color: Color(0xFF00838F)),
  ThemeColorOption(name: 'Blue', color: Color(0xFF1565C0)),
  ThemeColorOption(name: 'Indigo', color: Color(0xFF3949AB)),
  ThemeColorOption(name: 'Purple', color: Color(0xFF8E24AA)),
  ThemeColorOption(name: 'Rose', color: Color(0xFFC2185B)),
  ThemeColorOption(name: 'Red', color: Color(0xFFC62828)),
  ThemeColorOption(name: 'Orange', color: Color(0xFFEF6C00)),
];
