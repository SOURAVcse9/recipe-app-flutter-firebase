import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preferences_provider.dart';
import '../utils/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefsProvider = context.watch<PreferencesProvider>();
    final currentPrefs = prefsProvider.current;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSwitchRow(
            context,
            title: 'Recipe recommendations',
            subtitle: 'Get personalized recipe ideas',
            value: currentPrefs.recipeRecommendations,
            onChanged: (val) => prefsProvider.setRecipeRecommendations(val),
          ),
          const SizedBox(height: 12),
          _buildSwitchRow(
            context,
            title: 'New recipes',
            subtitle: 'Know when new recipes are added',
            value: currentPrefs.newRecipes,
            onChanged: (val) => prefsProvider.setNewRecipes(val),
          ),
          const SizedBox(height: 12),
          _buildSwitchRow(
            context,
            title: 'Cooking reminders',
            subtitle: 'Receive cooking reminders',
            value: currentPrefs.cookingReminders,
            onChanged: (val) => prefsProvider.setCookingReminders(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
