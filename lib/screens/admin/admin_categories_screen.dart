import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/food_category.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/safe_network_image.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeProvider = context.watch<RecipeProvider>();
    final categories = recipeProvider.categories;

    final filtered = categories.where((cat) {
      if (_search.trim().isEmpty) return true;
      return cat.name.toLowerCase().contains(_search.trim().toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            tooltip: 'Add Category',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),

          // Categories List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.folder_cross, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty ? 'No categories found.' : 'No matching categories.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return _buildCategoryItem(context, category, recipeProvider);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('New Category'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    FoodCategory category,
    RecipeProvider recipeProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: category.isActive ? Colors.white10 : Colors.redAccent.withAlpha(51),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: category.image != null && category.image!.isNotEmpty
                ? SafeNetworkImage(
                    imageUrl: category.image!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.primary.withAlpha(38),
                    child: const Icon(Iconsax.category, color: AppColors.primary, size: 22),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: category.isActive
                    ? Colors.green.withAlpha(38)
                    : Colors.red.withAlpha(38),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: category.isActive ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: FutureBuilder<int>(
            future: recipeProvider.getRecipeCountForCategory(category.name),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text(
                '$count recipe${count == 1 ? '' : 's'} linked',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              );
            },
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Iconsax.edit_2, size: 18, color: Colors.white70),
              tooltip: 'Edit Category',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditCategoryScreen(category: category),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                category.isActive ? Iconsax.eye_slash : Iconsax.eye,
                size: 18,
                color: category.isActive ? Colors.orangeAccent : Colors.greenAccent,
              ),
              tooltip: category.isActive ? 'Deactivate' : 'Activate',
              onPressed: () => _toggleActiveStatus(context, category, recipeProvider),
            ),
            IconButton(
              icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
              tooltip: 'Delete Category',
              onPressed: () => _confirmDeleteCategory(context, category, recipeProvider),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActiveStatus(
    BuildContext context,
    FoodCategory category,
    RecipeProvider recipeProvider,
  ) async {
    final newStatus = !category.isActive;
    final success = await recipeProvider.toggleCategoryActive(
      category.id,
      newStatus,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${category.name} is now ${newStatus ? 'Active' : 'Inactive'}.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    FoodCategory category,
    RecipeProvider recipeProvider,
  ) async {
    final count = await recipeProvider.getRecipeCountForCategory(category.name);
    if (!context.mounted) return;

    if (count > 0) {
      // Dependency warning dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Category in Use'),
          content: Text(
            'The category "${category.name}" has $count recipe(s) associated with it.\n\n'
            'Deleting it will leave those recipes uncategorized. We recommend deactivating it instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toggleActiveStatus(context, category, recipeProvider);
              },
              child: const Text('Deactivate Instead'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                await recipeProvider.deleteCategory(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted category ${category.name}.')),
                  );
                }
              },
              child: const Text('Delete Anyway', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Safe delete dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                await recipeProvider.deleteCategory(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted category ${category.name}.')),
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
}
