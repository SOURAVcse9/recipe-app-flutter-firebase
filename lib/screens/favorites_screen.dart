import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';
import '../widgets/state_views.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RecipeProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Favorites',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(RecipeProvider provider) {
    if (provider.recipeStatus == LoadStatus.loading) {
      return const LoadingView();
    }

    if (provider.recipeStatus == LoadStatus.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'Something went wrong.',
      );
    }

    final favorites = provider.favoriteRecipes;

    if (favorites.isEmpty) {
      return const EmptyView(
        icon: Iconsax.heart,
        title: 'No favorite recipes yet',
        subtitle: 'Start saving recipes you love.',
      );
    }

    return Builder(
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final recipe = favorites[index];
          return RecipeCard(
            recipe: recipe,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
              ),
            ),
            onFavoriteTap: () =>
                context.read<RecipeProvider>().toggleFavorite(recipe),
          );
        },
      ),
    );
  }
}
