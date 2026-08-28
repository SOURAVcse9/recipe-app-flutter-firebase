import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preferences_provider.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/recipe_card.dart';
import '../widgets/search_field.dart';
import '../widgets/state_views.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What are you cooking today?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find a recipe, scale the servings, and get cooking.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
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
