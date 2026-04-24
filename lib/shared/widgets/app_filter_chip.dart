import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppPalette.primary : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onSelected: onSelected,
      showCheckmark: false,
    );
  }
}
