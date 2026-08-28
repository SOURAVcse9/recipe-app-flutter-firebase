import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../utils/app_theme.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search recipes...',
  });

  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
        AppColors.textSecondary;

    return TextField(
      onChanged: onChanged,
      style: TextStyle(fontSize: 14.5, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: secondaryColor),
        prefixIcon: Icon(Iconsax.search_normal_1,
            size: 20, color: secondaryColor),
      ),
    );
  }
}
