import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/recipe_provider.dart';
import '../providers/review_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/state_views.dart';
import 'recipe_detail_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && mounted) {
        context.read<ReviewProvider>().watchUserReviews(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewProvider = context.watch<ReviewProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(context, reviewProvider, recipeProvider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReviewProvider reviewProvider,
    RecipeProvider recipeProvider,
  ) {
    final theme = Theme.of(context);

    if (reviewProvider.status == ReviewStatus.loading) {
      return const LoadingView();
    }

    if (reviewProvider.status == ReviewStatus.error) {
      return ErrorView(
        message: reviewProvider.errorMessage ?? 'Failed to load reviews.',
      );
    }

    final list = reviewProvider.userReviews;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.edit, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                "You haven't reviewed any recipes yet.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Explore recipes and share your experience.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
                child: const Text('Browse Recipes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final reviewMap = list[index];
        final recipeId = reviewMap['recipeId'] ?? '';
        final reviewId = reviewMap['reviewId'] ?? '';
        final rating = (reviewMap['rating'] ?? 0.0) as double;
        final reviewText = reviewMap['reviewText'] ?? '';
        final createdVal = reviewMap['createdAt'];
        final createdAt =
            createdVal is Timestamp ? createdVal.toDate() : DateTime.now();

        final recipe = recipeProvider.recipeById(recipeId);
        final recipeName =
            recipe.name.isNotEmpty ? recipe.name : 'Unknown Recipe';

        return Card(
          color: theme.cardColor,
          margin: const EdgeInsets.only(bottom: 16),
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
                    Expanded(
                      child: Text(
                        recipeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(recipeId: recipeId),
                            ),
                          );
                        } else if (value == 'edit') {
                          _showEditReviewDialog(
                              context, recipeId, rating, reviewText);
                        } else if (value == 'delete') {
                          reviewProvider.deleteReview(recipeId, reviewId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'view', child: Text('View Recipe')),
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit Review')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete Review')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (starIdx) {
                    return Icon(
                      starIdx < rating ? Iconsax.star1 : Iconsax.star,
                      size: 14,
                      color: AppColors.star,
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  reviewText,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(150) ??
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditReviewDialog(
    BuildContext context,
    String recipeId,
    double initialRating,
    String initialText,
  ) {
    double selectedRating = initialRating;
    final textController = TextEditingController(text: initialText);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF221F1B),
          title: Text(
            'Edit Review',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  return IconButton(
                    icon: Icon(
                      starVal <= selectedRating ? Iconsax.star1 : Iconsax.star,
                      color: AppColors.star,
                    ),
                    onPressed: () {
                      setStateDialog(() {
                        selectedRating = starVal;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Update your review text...',
                ),
                maxLines: 3,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save',
                  style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                context.read<ReviewProvider>().submitReview(
                      recipeId: recipeId,
                      rating: selectedRating,
                      reviewText: textController.text.trim(),
                    );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
