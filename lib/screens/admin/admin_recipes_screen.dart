import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/safe_network_image.dart';
import 'add_recipe_screen.dart';
import 'edit_recipe_screen.dart';

class AdminRecipesScreen extends StatefulWidget {
  const AdminRecipesScreen({super.key});

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  String _search = '';
  String _selectedCategory = 'All';
  String _statusFilter = 'All'; // 'All', 'Published', 'Draft'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeProvider = context.watch<RecipeProvider>();
    final recipes = recipeProvider.allRecipes;
    final categories = ['All', ...recipeProvider.categories.map((c) => c.name)];

    final filtered = recipes.where((recipe) {
      final matchesCat = _selectedCategory == 'All' ||
          recipe.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Published' && recipe.isPublished) ||
          (_statusFilter == 'Draft' && !recipe.isPublished);

      final q = _search.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          recipe.name.toLowerCase().contains(q) ||
          recipe.category.toLowerCase().contains(q) ||
          recipe.ingredientName.any((i) => i.toLowerCase().contains(q));

      return matchesCat && matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            tooltip: 'Add Recipe',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by recipe or ingredient...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),

          // Filter Row: Status Selector & Category Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Status Filter Segment
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isDense: true,
                      dropdownColor: theme.cardColor,
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13),
                      items: const [
                        DropdownMenuItem(
                            value: 'All', child: Text('All Status')),
                        DropdownMenuItem(
                            value: 'Published', child: Text('Published')),
                        DropdownMenuItem(value: 'Draft', child: Text('Drafts')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _statusFilter = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Category Filter Segment
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withAlpha(51),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: theme.cardColor,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white10,
                            ),
                            onSelected: (selected) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Recipes Count Indicator
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filtered.length} of ${recipes.length} recipes',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Recipe Items List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.book,
                            size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No recipes in this filter.'
                              : 'No matching recipes found.',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final recipe = filtered[index];
                      return _buildRecipeItem(context, recipe, recipeProvider);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('Add Recipe'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
          );
        },
      ),
    );
  }

  Widget _buildRecipeItem(
    BuildContext context,
    Recipe recipe,
    RecipeProvider recipeProvider,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recipe.isPublished
              ? Colors.white10
              : Colors.orangeAccent.withAlpha(76),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: SafeNetworkImage(
                    imageUrl: recipe.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: recipe.isPublished
                                ? Colors.green.withAlpha(38)
                                : Colors.orange.withAlpha(38),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            recipe.isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: recipe.isPublished
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(38),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            recipe.category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${recipe.time} min',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${recipe.calorie} kcal',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Iconsax.star1,
                                size: 13, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              recipe.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Publish / Unpublish Toggle
              Row(
                children: [
                  Switch(
                    value: recipe.isPublished,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: (val) async {
                      await recipeProvider.togglePublishRecipe(recipe.id, val);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${recipe.name} is now ${val ? 'Published' : 'Unpublished'}.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  Text(
                    recipe.isPublished ? 'Live' : 'Draft',
                    style: TextStyle(
                      fontSize: 12,
                      color: recipe.isPublished
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),

              // Edit & Delete Actions
              Row(
                children: [
                  TextButton.icon(
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.white70),
                    icon: const Icon(Iconsax.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 13)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditRecipeScreen(recipe: recipe),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Iconsax.trash,
                        size: 18, color: Colors.redAccent),
                    tooltip: 'Delete Recipe',
                    onPressed: () =>
                        _confirmDeleteRecipe(context, recipe, recipeProvider),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRecipe(
    BuildContext context,
    Recipe recipe,
    RecipeProvider recipeProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text(
            'Are you sure you want to permanently delete "${recipe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await recipeProvider.deleteRecipe(recipe.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted recipe ${recipe.name}.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
