import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/food_category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _storageService = StorageService();

  bool _isActive = true;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _uploadedImageUrl;
  XFile? _selectedImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _selectedImageFile = file;
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final recipeProvider = context.read<RecipeProvider>();
    final authProvider = context.read<AuthProvider>();

    setState(() => _isLoading = true);

    // 1. Check duplicate category name
    final isTaken = await recipeProvider.isCategoryNameTaken(name);
    if (isTaken) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A category named "$name" already exists.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // 2. Upload image if selected
      String? imageUrl = _uploadedImageUrl;
      if (_selectedImageFile != null) {
        final categoryId = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
        imageUrl = await _storageService.uploadCategoryImage(
          categoryId: categoryId,
          file: _selectedImageFile!,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      }

      // 3. Create model and save to Firestore
      final categoryId = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final newCategory = FoodCategory(
        id: categoryId,
        name: name,
        image: imageUrl,
        isActive: _isActive,
      );

      final success = await recipeProvider.createCategory(
        newCategory,
        authProvider.currentUser?.uid ?? '',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$name" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(recipeProvider.errorMessage ?? 'Failed to save category.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              Text(
                'Category Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white24, style: BorderStyle.solid),
                  ),
                  child: _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _selectedImageFile!.path,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Iconsax.image, size: 40),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Iconsax.edit,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Change',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.image,
                                size: 40, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload category image',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'JPG, PNG, WEBP • Max 5 MB',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                ),
              ),

              if (_uploadProgress > 0 && _uploadProgress < 1.0) ...[
                const SizedBox(height: 8),
                LinearProgressProgressIndicator(value: _uploadProgress),
              ],

              const SizedBox(height: 24),

              // Category Name
              Text(
                'Category Name *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Italian, Breakfast, Desserts',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Active Switch
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Active Status',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Active categories are visible to audience users',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveCategory,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Create Category',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LinearProgressProgressIndicator extends StatelessWidget {
  final double value;
  const LinearProgressProgressIndicator({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
