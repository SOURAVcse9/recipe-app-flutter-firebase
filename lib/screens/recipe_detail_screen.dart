import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../providers/preferences_provider.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_theme.dart';
import '../utils/ingredient_scaler.dart';
import '../widgets/favorite_button.dart';
import '../widgets/ingredient_tile.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/rating_widget.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/state_views.dart';

/// Renders real-time details from Firestore for the selected recipe ID,
/// adapting layout displays to theme and content visibility preferences.
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RecipeProvider>();
    final prefs = context.watch<PreferencesProvider>().current;

    if (provider.recipeStatus == LoadStatus.loading) {
      return const Scaffold(body: LoadingView());
    }

    final recipe = provider.recipeById(recipeId);

    if (recipe == null) {
      return const Scaffold(
        body: EmptyView(
          title: 'Recipe not found',
          subtitle: 'This recipe may have been removed.',
        ),
      );
    }

    final quantity = provider.quantityFor(recipe.id,
        defaultQuantity: prefs.defaultServingQuantity);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: const _RoundBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeNetworkImage(
                url: recipe.image,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      FavoriteButton(
                        isFavorite: recipe.isFavorite,
                        onTap: () => context
                            .read<RecipeProvider>()
                            .toggleFavorite(recipe),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.category,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
                          AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (prefs.showCalories) ...[
                        _StatChip(
                          icon: Iconsax.flash_1,
                          label: '${recipe.calorie} Cal',
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (prefs.showCookingTime) ...[
                        _StatChip(
                          icon: Iconsax.clock,
                          label: '${recipe.time} Mins',
                        ),
                        const SizedBox(width: 10),
                      ],
                      _StatChip(
                        icon: Iconsax.star1,
                        label: '${recipe.rating.toStringAsFixed(1)} Star',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        RatingWidget(rating: recipe.rating),
                        const SizedBox(width: 6),
                        Text(
                          '(${recipe.review} Reviews)',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.textTheme.bodyMedium?.color
                                    ?.withAlpha(204) ??
                                AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      QuantitySelector(
                        quantity: quantity,
                        onIncrement: () => context
                            .read<RecipeProvider>()
                            .incrementQuantity(recipe.id,
                                defaultQuantity: prefs.defaultServingQuantity),
                        onDecrement: () => context
                            .read<RecipeProvider>()
                            .decrementQuantity(recipe.id,
                                defaultQuantity: prefs.defaultServingQuantity),
                      ),
                    ],
                  ),
                  if (recipe.hasMismatchedIngredientArrays) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Some ingredient data looks incomplete for this '
                      'recipe — showing what we can safely match.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.textTheme.bodyMedium?.color
                                ?.withAlpha(204) ??
                            AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (recipe.safeIngredientCount == 0)
                    Text(
                      'No ingredients listed for this recipe yet.',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color
                                ?.withAlpha(204) ??
                            AppColors.textSecondary,
                      ),
                    )
                  else
                    ...List.generate(recipe.safeIngredientCount, (i) {
                      final scaled = IngredientScaler.scale(
                        recipe.ingredientAmount[i],
                        quantity,
                      );
                      return IngredientTile(
                        imageUrl: recipe.ingredientImage[i],
                        name: recipe.ingredientName[i],
                        scaledAmount: scaled,
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2F2A25) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
