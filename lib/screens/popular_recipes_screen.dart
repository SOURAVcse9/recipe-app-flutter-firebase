import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preferences_provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../widgets/state_views.dart';
import 'recipe_detail_screen.dart';

class PopularRecipesScreen extends StatelessWidget {
  const PopularRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RecipeProvider>();
    final prefs = context.watch<PreferencesProvider>().current;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '🔥 Popular Recipes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(context, provider, prefs),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecipeProvider provider,
    dynamic prefs,
  ) {
    if (provider.recipeStatus == LoadStatus.loading) {
      return const LoadingView();
    }

    if (provider.recipeStatus == LoadStatus.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'Failed to load recipes.',
      );
    }

    final recipes = List<Recipe>.from(provider.filteredRecipes(prefs))
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));

    if (recipes.isEmpty) {
      return const EmptyView(
        title: 'No popular recipes available',
        subtitle: 'Start exploring recipes to see popularity counts grow.',
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
