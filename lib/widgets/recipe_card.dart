import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/recipe.dart';
import '../utils/app_theme.dart';
import 'favorite_button.dart';
import 'rating_widget.dart';
import 'safe_network_image.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SafeNetworkImage(
                      url: recipe.image,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.md),
                        topRight: Radius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteButton(
                      isFavorite: recipe.isFavorite,
                      onTap: onFavoriteTap,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Iconsax.flash_1,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.calorie} Cal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Iconsax.clock,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.time} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RatingWidget(rating: recipe.rating, size: 12.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
