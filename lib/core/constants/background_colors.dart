import 'package:flutter/material.dart';

/// A background choice pairs a light-mode and dark-mode shade together,
/// unlike accent color (a single seed Material derives both from) —
/// there's no sensible way to derive "the dark version of white."
///
/// [light] and [dark] are both null for "Default": Material's own
/// accent-tinted surface colors, left completely alone. Every other
/// option overrides them.
class BackgroundOption {
  final String name;
  final Color? light;
  final Color? dark;

  const BackgroundOption({required this.name, this.light, this.dark});

  bool get isDefault => light == null && dark == null;
}

const List<BackgroundOption> kBackgroundOptions = [
  BackgroundOption(name: 'Default'),
  BackgroundOption(name: 'Pure', light: Color(0xFFFFFFFF), dark: Color(0xFF000000)),
  BackgroundOption(
    name: 'Cool Gray',
    light: Color(0xFFF1F2F4),
    dark: Color(0xFF17181A),
  ),
  BackgroundOption(
    name: 'Warm Gray',
    light: Color(0xFFF6F3EE),
    dark: Color(0xFF1E1B17),
  ),
];
