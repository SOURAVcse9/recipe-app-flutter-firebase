import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preferences_provider.dart';
import '../utils/app_theme.dart';

class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefsProvider = context.watch<PreferencesProvider>();
    final currentPrefs = prefsProvider.current;
    final theme = Theme.of(context);

    // Map theme string to display value
    String themeDisplay;
    switch (currentPrefs.themeMode) {
      case 'light':
        themeDisplay = 'Light Theme';
        break;
      case 'dark':
        themeDisplay = 'Dark Theme';
        break;
      case 'system':
      default:
        themeDisplay = 'System Default';
        break;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('App preferences'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildHeader(context, 'Appearance'),
          _buildPreferencesCard(
            context,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Theme mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: themeDisplay,
                  underline: const SizedBox(),
                  dropdownColor: theme.cardColor,
                  onChanged: (val) {
                    if (val == 'Light Theme') {
                      prefsProvider.setThemeMode('light');
                    } else if (val == 'Dark Theme') {
                      prefsProvider.setThemeMode('dark');
                    } else {
                      prefsProvider.setThemeMode('system');
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Light Theme',
                      child:
                          Text('Light Theme', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'Dark Theme',
                      child: Text('Dark Theme', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'System Default',
                      child: Text('System Default',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildHeader(context, 'Recipe settings'),
          _buildPreferencesCard(
            context,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Default serving quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    DropdownButton<int>(
                      value: currentPrefs.defaultServingQuantity,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      onChanged: (val) {
                        if (val != null) {
                          prefsProvider.setDefaultServingQuantity(val);
                        }
                      },
                      items: const [1, 2, 3, 4, 5, 6, 8, 10, 12]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text('$e',
                                  style: const TextStyle(fontSize: 14)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                Divider(color: theme.dividerColor, height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Show calories',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Switch(
                      value: currentPrefs.showCalories,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => prefsProvider.setShowCalories(val),
                    ),
                  ],
                ),
                Divider(color: theme.dividerColor, height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Show cooking time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Switch(
                      value: currentPrefs.showCookingTime,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => prefsProvider.setShowCookingTime(val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildHeader(context, 'Search preferences'),
          _buildPreferencesCard(
            context,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Case-insensitive search',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Switch(
                  value: currentPrefs.caseInsensitiveSearch,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) =>
                      prefsProvider.setCaseInsensitiveSearch(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color:
              Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(178) ??
                  AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}
