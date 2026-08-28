import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/preferences_provider.dart';
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
    final theme = Theme.of(context);
    final prefs = context.watch<PreferencesProvider>().current;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (prefs.showCalories || prefs.showCookingTime)
                    Row(
                      children: [
                        if (prefs.showCalories) ...[
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
                        ],
                        if (prefs.showCalories && prefs.showCookingTime)
                          const SizedBox(width: 10),
                        if (prefs.showCookingTime) ...[
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
