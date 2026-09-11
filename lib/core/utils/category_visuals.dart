import 'package:flutter/material.dart';

/// Maps the string identifiers stored in [Category.icon]/[Category.color]
/// to actual Flutter values. Kept as plain strings in the database so
/// the icon set can grow without a schema/enum migration.
const Map<String, IconData> kCategoryIconOptions = {
  'payments': Icons.payments,
  'receipt_long': Icons.receipt_long,
  'shopping_cart': Icons.shopping_cart,
  'celebration': Icons.celebration,
  'home': Icons.home,
  'bolt': Icons.bolt,
  'wifi': Icons.wifi,
  'shield': Icons.shield_outlined,
  'directions_car': Icons.directions_car,
  'local_hospital': Icons.local_hospital,
  'repeat': Icons.repeat,
  'account_balance': Icons.account_balance,
  'child_care': Icons.child_care,
  'school': Icons.school,
  'flight': Icons.flight,
  'pets': Icons.pets,
  'savings': Icons.savings,
  'restaurant': Icons.restaurant,
  'movie': Icons.movie,
  'shopping_bag': Icons.shopping_bag,
  'fitness_center': Icons.fitness_center,
  'card_giftcard': Icons.card_giftcard,
  'checkroom': Icons.checkroom,
  'build': Icons.build,
  'category': Icons.category,
};

const List<String> kCategoryColorOptions = [
  '#2E7D32',
  '#C62828',
  '#1565C0',
  '#8E24AA',
  '#EF6C00',
  '#00838F',
  '#6D4C41',
  '#455A64',
  '#C2185B',
  '#3949AB',
  '#37474F',
];

IconData iconForKey(String key) => kCategoryIconOptions[key] ?? Icons.category;

Color colorFromHex(String hex) {
  final value = hex.replaceFirst('#', '');
  return Color(int.parse('FF$value', radix: 16));
}
