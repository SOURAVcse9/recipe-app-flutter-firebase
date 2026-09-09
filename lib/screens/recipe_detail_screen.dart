import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/preferences_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/recently_viewed_provider.dart';
import '../providers/review_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../models/review.dart';
import '../utils/app_theme.dart';
import '../utils/ingredient_scaler.dart';
import '../widgets/favorite_button.dart';
import '../widgets/ingredient_tile.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/rating_widget.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/state_views.dart';
import '../widgets/timer_widget.dart';

/// Renders real-time details from Firestore for the selected recipe ID,
/// adapting layout displays to theme and content visibility preferences.
class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RecipeProvider>().resetQuantity(widget.recipeId);
        // Record recently viewed and increment viewCount
        context
            .read<RecentlyViewedProvider>()
            .addRecipeToRecentlyViewed(widget.recipeId);
        context
            .read<RecipeProvider>()
            .incrementRecipeViewCount(widget.recipeId);
        // Stream reviews
        context.read<ReviewProvider>().watchReviews(widget.recipeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<RecipeProvider>();
    final prefs = context.watch<PreferencesProvider>().current;

    if (provider.recipeStatus == LoadStatus.loading) {
      return const Scaffold(body: LoadingView());
    }

    final recipe = provider.recipeById(widget.recipeId);

    if (recipe.id.isEmpty) {
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
                      color:
                          theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
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
                        color:
                            theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
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
                        color:
                            theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
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
                  if (recipe.instructions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Cooking Instructions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(recipe.instructions.length, (index) {
                      final stepNum = index + 1;
                      final stepText = recipe.instructions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$stepNum',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stepText,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final dynamicAmounts = <String>[];
                            for (int i = 0;
                                i < recipe.safeIngredientCount;
                                i++) {
                              dynamicAmounts.add(
                                IngredientScaler.scale(
                                  recipe.ingredientAmount[i],
                                  quantity,
                                ),
                              );
                            }
                            context
                                .read<ShoppingListProvider>()
                                .addIngredientsToShoppingList(
                                  recipeId: recipe.id,
                                  recipeName: recipe.name,
                                  names: recipe.ingredientName,
                                  amounts: dynamicAmounts,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Added ingredients to shopping list!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.cardColor,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                          icon: const Icon(Iconsax.shopping_bag),
                          label: const Text('Add to Shopping List',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (recipe.time > 0) {
                              showDialog(
                                context: context,
                                builder: (_) => TimerWidget(
                                  initialMinutes: recipe.time,
                                  recipeName: recipe.name,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'This recipe has no cooking time listed.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                          icon: const Icon(Iconsax.timer_1),
                          label: const Text('Start Cooking',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 20),
                  const _ReviewsSectionHeader(),
                  const SizedBox(height: 16),
                  _ReviewsList(recipeId: recipe.id),
                  const SizedBox(height: 24),
                  _WriteReviewSection(recipeId: recipe.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSectionHeader extends StatelessWidget {
  const _ReviewsSectionHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewProvider = context.watch<ReviewProvider>();
    final count = reviewProvider.reviews.length;
    final avg = count > 0
        ? reviewProvider.reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            count
        : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reviews',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Row(
          children: [
            const Icon(Iconsax.star1, color: AppColors.star, size: 18),
            const SizedBox(width: 4),
            Text(
              '${avg.toStringAsFixed(1)} ($count Reviews)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewsList extends StatelessWidget {
  final String recipeId;

  const _ReviewsList({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ReviewProvider>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (provider.status == ReviewStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == ReviewStatus.error) {
      return Text('Failed to load reviews: ${provider.errorMessage}');
    }

    final reviews = provider.reviews;

    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No reviews yet. Be the first to review this recipe!',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        final isOwner = review.userId == currentUserId;

        return Card(
          color: theme.cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Iconsax.trash,
                            size: 16, color: AppColors.error),
                        onPressed: () =>
                            provider.deleteReview(recipeId, review.id),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (starIdx) {
                    return Icon(
                      starIdx < review.rating ? Iconsax.star1 : Iconsax.star,
                      size: 14,
                      color: AppColors.star,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  review.reviewText,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WriteReviewSection extends StatefulWidget {
  final String recipeId;

  const _WriteReviewSection({required this.recipeId});

  @override
  State<_WriteReviewSection> createState() => _WriteReviewSectionState();
}

class _WriteReviewSectionState extends State<_WriteReviewSection> {
  double _rating = 5.0;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ReviewProvider>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final existingReview = provider.reviews.firstWhere(
      (r) => r.userId == currentUserId,
      orElse: () => const Review(
          id: '', userId: '', userName: '', rating: 0, reviewText: ''),
    );

    final isEditing = existingReview.id.isNotEmpty;

    if (isEditing && _textController.text.isEmpty && _rating == 5.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _rating = existingReview.rating;
            _textController.text = existingReview.reviewText;
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Update Your Review' : 'Rate & Review this Recipe',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final starVal = index + 1.0;
            return IconButton(
              icon: Icon(
                starVal <= _rating ? Iconsax.star1 : Iconsax.star,
                color: AppColors.star,
              ),
              onPressed: () {
                setState(() {
                  _rating = starVal;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Share your experience with this recipe...',
            hintStyle: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(128)),
            fillColor: theme.cardColor,
            filled: true,
          ),
          maxLines: 3,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_textController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please write a review comment.')),
                );
                return;
              }
              context.read<ReviewProvider>().submitReview(
                    recipeId: widget.recipeId,
                    rating: _rating,
                    reviewText: _textController.text.trim(),
                  );
              if (!isEditing) {
                _textController.clear();
                setState(() {
                  _rating = 5.0;
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        isEditing ? 'Review updated!' : 'Review submitted!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text(
              isEditing ? 'Update Review' : 'Submit Review',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
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
          icon: Icon(Iconsax.arrow_left_2,
              color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
