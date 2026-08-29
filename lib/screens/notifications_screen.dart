import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/preferences_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AuthorizationStatus _status = AuthorizationStatus.notDetermined;
  bool _checkingStatus = true;
  bool _isSupported = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionStatus();
    });
  }

  Future<void> _checkPermissionStatus() async {
    final supported = NotificationService.instance.isSupported;
    if (!supported) {
      if (mounted) {
        setState(() {
          _isSupported = false;
          _checkingStatus = false;
        });
      }
      return;
    }

    final status = await NotificationService.instance.getAuthorizationStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _isSupported = true;
        _checkingStatus = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final settings = await NotificationService.instance.requestPermission();
    if (settings != null && mounted) {
      setState(() {
        _status = settings.authorizationStatus;
      });
    }
  }

  Widget _buildPermissionStatusCard(ThemeData theme) {
    if (_checkingStatus) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 50,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }

    if (!_isSupported) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Push notifications are not supported on this platform.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(128),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_status == AuthorizationStatus.denied) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(26),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.red.withAlpha(51)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notifications are blocked. Please enable them in your browser or device system settings to receive recipe updates.',
                style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_status == AuthorizationStatus.notDetermined) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stay Updated!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enable push notifications to receive real-time personalized recipe recommendations and updates.',
              style: TextStyle(
                fontSize: 12.5,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(178),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              child: const Text('Enable Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.green.withAlpha(51)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Push Notifications: Enabled',
              style: TextStyle(fontSize: 13.5, color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

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
          _buildPermissionStatusCard(theme),
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
