import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'about_app_screen.dart';
import 'app_preferences_screen.dart';
import 'notifications_screen.dart';
import 'shopping_list_screen.dart';
import 'recently_viewed_screen.dart';
import 'my_reviews_screen.dart';
import 'favorites_screen.dart';

/// Renders option cards to configure notifications, app preferences, and about info.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile;
    final name = profile?['name'] ?? authProvider.currentUser?.displayName ?? 'Anonymous User';
    final email = profile?['email'] ?? authProvider.currentUser?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 24),
                // Dynamic profile header card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ?? AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Option cards list
                _SettingsTile(
                  icon: Iconsax.heart,
                  label: 'My Favorites',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Scaffold(body: FavoritesScreen())),
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.edit,
                  label: 'My Reviews',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.shopping_bag,
                  label: 'Shopping List',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.clock,
                  label: 'Recently Viewed',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecentlyViewedScreen()),
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.notification,
                  label: 'Notifications',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.setting_2,
                  label: 'App preferences',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppPreferencesScreen()),
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.info_circle,
                  label: 'About this app',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutConfirmation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withAlpha(25),
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(color: AppColors.error, width: 1),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Iconsax.logout, size: 18),
                    label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF221F1B),
        title: Text(
          'Logout',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            Icon(Iconsax.arrow_right_3,
                size: 16,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                    AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
