import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().userProfile;
    final currentName = profile?['name'] ??
        context.read<AuthProvider>().currentUser?.displayName ??
        '';
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final success =
        await provider.updateDisplayName(_nameController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name cannot be empty.';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters.';
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
                      : const Text('Save Changes',
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
