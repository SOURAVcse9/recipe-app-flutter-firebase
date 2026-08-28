import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../utils/app_theme.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About this app'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(
              Iconsax.reserve,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Recipe App',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
                    AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Discover delicious recipes, explore ingredients, scale servings, and save your favorite meals.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: 'Features',
              items: [
                'Browse recipes',
                'Search recipes',
                'Filter by category',
                'Scale ingredients dynamically',
                'Save favorites',
                'Real-time recipe updates',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'Technology Stack',
              items: [
                'Flutter',
                'Firebase Core & Authentication',
                'Cloud Firestore',
                'Provider State Management',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<String> items}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                  AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
