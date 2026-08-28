import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'safe_network_image.dart';

class IngredientTile extends StatelessWidget {
  const IngredientTile({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.scaledAmount,
  });

  final String imageUrl;
  final String name;
  final String scaledAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: SafeNetworkImage(
              url: imageUrl,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            scaledAmount,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
