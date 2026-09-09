import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'about_app_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'app_preferences_screen.dart';
import 'notifications_screen.dart';
import 'shopping_list_screen.dart';
import 'recently_viewed_screen.dart';
import 'my_reviews_screen.dart';
import 'favorites_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

/// Renders options and dynamic profiles displaying provider indicators, photos,
/// verification flags, and custom settings widgets.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile;
    final user = authProvider.currentUser;

    final name = profile?['name'] ?? user?.displayName ?? 'Anonymous User';
    final email = profile?['email'] ?? user?.email ?? '';
    final photoUrl = profile?['photoUrl'] ?? user?.photoURL;
    final providerType = profile?['provider'] ??
        (user?.providerData.any((p) => p.providerId == 'google.com') == true ? 'google' : 'password');
    final isVerified = user?.emailVerified ?? false;
    final isAdmin = authProvider.isAdmin;
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
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(38),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Iconsax.shield_tick, color: Colors.white, size: 20),
                      ),
                      title: const Text(
                        'Admin Dashboard',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Return to administrative control panel',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
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
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
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
                            const SizedBox(height: 8),
                            // Verification and Provider status layout
                            Row(
                              children: [
                                Icon(
                                  isVerified ? Icons.verified_user : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: isVerified ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isVerified ? '✓ Verified' : '⚠ Unverified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isVerified ? Colors.green : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: providerType == 'google' ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    providerType == 'google' ? 'Google Account' : 'Email/Password',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: providerType == 'google' ? Colors.blue : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Options list
                _SettingsTile(
                  icon: Iconsax.user_edit,
                  label: 'Edit Profile',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
                if (providerType == 'password')
                  _SettingsTile(
                    icon: Iconsax.key,
                    label: 'Change Password',
                    onTap: () {
                      if (!isVerified) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please verify your email before continuing.')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      );
                    },
                  ),
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
