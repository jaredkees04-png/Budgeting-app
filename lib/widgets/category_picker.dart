import 'package:flutter/material.dart';

import '../core/utils/category_visuals.dart';
import '../data/database/app_database.dart';

class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final selected = category.id == selectedCategoryId;
        final color = colorFromHex(category.color);
        return ChoiceChip(
          selected: selected,
          onSelected: (_) => onSelected(category.id),
          avatar: Icon(
            iconForKey(category.icon),
            size: 18,
            color: selected ? Colors.white : color,
          ),
          label: Text(category.name),
          selectedColor: color,
          labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        );
      }).toList(),
    );
  }
}
