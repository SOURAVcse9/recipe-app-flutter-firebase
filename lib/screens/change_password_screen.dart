import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final success = await provider.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AuthProvider>();

    // 1. Google Provider check
    final providerType = provider.userProfile?['provider'] ??
        (provider.currentUser?.providerData
                    .any((p) => p.providerId == 'google.com') ==
                true
            ? 'google'
            : 'password');

    if (providerType == 'google') {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.g_mobiledata,
                    size: 72, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  'Google Authentication',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account is secured via Google Sign-In. Password management is handled by Google and cannot be modified within this app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Email verification check
    final isVerified = provider.currentUser?.emailVerified ?? false;
    if (!isVerified) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 72, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'Email Verification Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please verify your email before continuing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Change Password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentController,
                  obscureText: true,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppColors.primary),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Current password cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newController,
                  obscureText: true,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon:
                        Icon(Icons.lock_reset, color: AppColors.primary),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'New password cannot be empty.';
                    }
                    if (val.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    if (!val.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain at least one uppercase letter.';
                    }
                    if (!val.contains(RegExp(r'[a-z]'))) {
                      return 'Password must contain at least one lowercase letter.';
                    }
                    if (!val.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppColors.primary),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please confirm your new password.';
                    }
                    if (val != _newController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (provider.error != null) ...[
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: provider.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  child: provider.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Update Password',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
