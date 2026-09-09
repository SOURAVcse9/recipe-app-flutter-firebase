import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../providers/recently_viewed_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';
import '../widgets/state_views.dart';
import 'recipe_detail_screen.dart';

class RecentlyViewedScreen extends StatelessWidget {
  const RecentlyViewedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentlyViewedProvider = context.watch<RecentlyViewedProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Recently Viewed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(context, recentlyViewedProvider, recipeProvider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecentlyViewedProvider recentlyViewedProvider,
    RecipeProvider recipeProvider,
  ) {
    if (recentlyViewedProvider.status == RecentlyViewedStatus.loading) {
      return const LoadingView();
    }

    if (recentlyViewedProvider.status == RecentlyViewedStatus.error) {
      return ErrorView(
        message: recentlyViewedProvider.errorMessage ??
            'Failed to load recently viewed history.',
      );
    }

    final history = recentlyViewedProvider.recentlyViewed;

    // Resolve the actual recipes from the in-memory pool in RecipeProvider
    final recipes = history
        .map((h) => recipeProvider.recipeById(h.recipeId))
        .where((r) => r.id.isNotEmpty)
        .toList();

    if (recipes.isEmpty) {
      return const EmptyView(
        icon: Iconsax.clock,
        title: 'No recently viewed recipes',
        subtitle: 'Start exploring recipes to see them here.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
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
    );
  }
}
