import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/state_views.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ShoppingListProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Shopping List',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (provider.items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_completed') {
                  provider.clearCompleted();
                } else if (value == 'clear_all') {
                  provider.clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Text('Clear Completed'),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Text('Clear All'),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, ShoppingListProvider provider) {
    final theme = Theme.of(context);

    if (provider.status == ShoppingListStatus.loading) {
      return const LoadingView();
    }

    if (provider.status == ShoppingListStatus.error) {
      return ErrorView(message: provider.errorMessage ?? 'Failed to load shopping list.');
    }

    final items = provider.items;

    if (items.isEmpty) {
      return const EmptyView(
        icon: Iconsax.shopping_bag,
        title: 'Your shopping list is empty',
        subtitle: 'Add ingredients from a recipe to get started.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: ListTile(
            leading: Checkbox(
              activeColor: AppColors.primary,
              value: item.completed,
              onChanged: (val) {
                if (val != null) {
                  provider.toggleItemCompleted(item.id, val);
                }
              },
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
                decoration: item.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${item.amount} • From ${item.recipeName}',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ?? AppColors.textSecondary,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Iconsax.trash, size: 18, color: AppColors.error),
              onPressed: () => provider.deleteItem(item.id),
            ),
          ),
        );
      },
    );
  }
}
