import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/food_category.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/safe_network_image.dart';

class EditCategoryScreen extends StatefulWidget {
  final FoodCategory category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imageController;

  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _imageController = TextEditingController(text: widget.category.image ?? '');
    _isActive = widget.category.isActive;
    _imageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final imageUrl = _imageController.text.trim().isEmpty
        ? null
        : _imageController.text.trim();
    final recipeProvider = context.read<RecipeProvider>();

    setState(() => _isLoading = true);

    // Check duplicate name if changed
    if (name.toLowerCase() != widget.category.name.toLowerCase()) {
      final isTaken = await recipeProvider.isCategoryNameTaken(name,
          excludeId: widget.category.id);
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
    }

    try {
      final updatedCategory = widget.category.copyWith(
        name: name,
        image: imageUrl,
        isActive: _isActive,
      );

      final success = await recipeProvider.updateCategory(updatedCategory);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                recipeProvider.errorMessage ?? 'Failed to update category.'),
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
    final previewUrl = _imageController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview Card
              Text(
                'Category Image Preview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white24, style: BorderStyle.solid),
                ),
                child: previewUrl.isNotEmpty && _isValidUrl(previewUrl)
                    ? SafeNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(16),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.image,
                              size: 40, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text(
                            'Enter HTTPS Image URL Below',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Live image preview will render here',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // Image URL Field
              Text(
                'Image URL (HTTPS)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _imageController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://images.unsplash.com/...',
                  prefixIcon: const Icon(Iconsax.link, size: 18),
                  suffixIcon: previewUrl.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _imageController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val != null &&
                      val.trim().isNotEmpty &&
                      !_isValidUrl(val)) {
                    return 'Please enter a valid HTTP/HTTPS URL';
                  }
                  return null;
                },
              ),

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
                          'Inactive categories are hidden from audience users',
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

              // Save Button
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
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Changes',
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
