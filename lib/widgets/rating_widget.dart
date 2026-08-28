import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../utils/app_theme.dart';

class RatingWidget extends StatelessWidget {
  const RatingWidget({
    super.key,
    required this.rating,
    this.size = 14,
    this.showBackground = false,
  });

  final double rating;
  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.star1, size: size, color: AppColors.star),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );

    if (!showBackground) return content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: content,
    );
  }
}
