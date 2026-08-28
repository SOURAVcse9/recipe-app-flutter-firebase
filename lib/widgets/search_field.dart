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
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Iconsax.search_normal_1,
            size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
