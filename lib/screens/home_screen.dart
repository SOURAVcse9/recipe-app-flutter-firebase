import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preferences_provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/recipe_card.dart';
import '../widgets/search_field.dart';
import '../widgets/state_views.dart';
import 'recipe_detail_screen.dart';
import 'popular_recipes_screen.dart';
import 'top_rated_recipes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What are you cooking today?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find a recipe, scale the servings, and get cooking.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
                          AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SearchField(
                    onChanged: (value) =>
                        context.read<RecipeProvider>().setSearchQuery(value),
                  ),
                  const SizedBox(height: 18),
                  const _CategoryRow(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const _RecipeGridSliver(),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    if (provider.categoryStatus == LoadStatus.loading &&
        provider.categoryNames.length <= 1) {
      return const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.categoryNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final name = provider.categoryNames[index];
          return CategoryChip(
            label: name,
            selected: provider.selectedCategory == name,
            onTap: () => context.read<RecipeProvider>().setSelectedCategory(
                  name,
                ),
          );
        },
      ),
    );
  }
}

class _RecipeGridSliver extends StatelessWidget {
  const _RecipeGridSliver();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    if (provider.recipeStatus == LoadStatus.loading) {
      return const SliverFillRemaining(child: LoadingView());
    }

    if (provider.recipeStatus == LoadStatus.error) {
      return SliverFillRemaining(
        child: ErrorView(
          message: provider.errorMessage ?? 'Something went wrong.',
          onRetry: () => context.read<RecipeProvider>().retry(),
        ),
      );
    }

    final prefs = context.watch<PreferencesProvider>().current;
    final recipes = provider.filteredRecipes(prefs);

    if (recipes.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyView(
          title: 'No recipes found',
          subtitle: 'Try a different search term or category.',
        ),
      );
    }

    final isDefaultState = provider.selectedCategory == 'All' && provider.searchQuery.trim().isEmpty;

    if (isDefaultState) {
      // Feature 10: Dynamic discovery sections
      final topRated = List<Recipe>.from(recipes)
        ..sort((a, b) {
          if (a.review == 0 && b.review > 0) return 1;
          if (b.review == 0 && a.review > 0) return -1;
          return b.rating.compareTo(a.rating);
        });
      final topRatedSliced = topRated.take(5).toList();

      final popular = List<Recipe>.from(recipes)
        ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
      final popularSliced = popular.take(5).toList();

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _HorizontalRecipeList(
              title: '⭐ Top Rated',
              recipes: topRatedSliced,
            ),
            const SizedBox(height: 12),
            _HorizontalRecipeList(
              title: '🔥 Popular',
              recipes: popularSliced,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'All Recipes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
            ),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
          childCount: recipes.length,
        ),
      ),
    );
  }
}

class _HorizontalRecipeList extends StatelessWidget {
  final String title;
  final List<Recipe> recipes;

  const _HorizontalRecipeList({required this.title, required this.recipes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => title.contains('Popular')
                          ? const PopularRecipesScreen()
                          : const TopRatedRecipesScreen(),
                    ),
                  );
                },
                child: const Text('See All', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return SizedBox(
                width: 160,
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                    ),
                  ),
                  onFavoriteTap: () =>
                      context.read<RecipeProvider>().toggleFavorite(recipe),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
