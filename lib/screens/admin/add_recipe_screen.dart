import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _IngredientFormEntry {
  final TextEditingController nameController;
  final TextEditingController amountController;
  String imageUrl = '';
  XFile? localImageFile;

  _IngredientFormEntry({
    String name = '',
    String amount = '',
  })  : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _calorieController = TextEditingController(text: '300');
  final _timeController = TextEditingController(text: '25');
  final _ratingController = TextEditingController(text: '4.8');
  final _reviewsController = TextEditingController(text: '0');

  String? _selectedCategory;
  bool _isPublished = true;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusMessage = '';

  XFile? _recipeImageFile;
  final _storageService = StorageService();

  // Dynamic ingredient list
  final List<_IngredientFormEntry> _ingredientEntries = [
    _IngredientFormEntry(),
  ];

  // Dynamic instructions list
  final List<TextEditingController> _instructionControllers = [
    TextEditingController(),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _timeController.dispose();
    _ratingController.dispose();
    _reviewsController.dispose();
    for (final ing in _ingredientEntries) {
      ing.dispose();
    }
    for (final inst in _instructionControllers) {
      inst.dispose();
    }
    super.dispose();
  }

  Future<void> _pickRecipeImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      setState(() => _recipeImageFile = file);
    }
  }

  Future<void> _pickIngredientImage(int index) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() {
        _ingredientEntries[index].localImageFile = file;
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredientEntries.add(_IngredientFormEntry());
    });
  }

  void _removeIngredient(int index) {
    if (_ingredientEntries.length <= 1) return;
    setState(() {
      final removed = _ingredientEntries.removeAt(index);
      removed.dispose();
    });
  }

  void _addInstruction() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    if (_instructionControllers.length <= 1) return;
    setState(() {
      final removed = _instructionControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_isPublished && _recipeImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A published recipe must have an image uploaded.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate ingredients
    final validIngredients = _ingredientEntries
        .where((e) => e.nameController.text.trim().isNotEmpty && e.amountController.text.trim().isNotEmpty)
        .toList();

    if (_isPublished && validIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid ingredient (name & amount required).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final recipeProvider = context.read<RecipeProvider>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUser?.uid ?? '';

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatusMessage = 'Uploading recipe image...';
    });

    try {
      final recipeName = _nameController.text.trim();
      final sanitizedName = recipeName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final recipeId = '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Upload Main Recipe Image
      String recipeImageUrl = '';
      if (_recipeImageFile != null) {
        recipeImageUrl = await _storageService.uploadRecipeImage(
          recipeId: recipeId,
          file: _recipeImageFile!,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress * 0.5);
            }
          },
        );
      }

      // 2. Upload Ingredient Images if any
      final finalIngredients = <IngredientItem>[];
      final totalIng = validIngredients.length;

      for (var i = 0; i < totalIng; i++) {
        final entry = validIngredients[i];
        String ingImageUrl = entry.imageUrl;

        if (entry.localImageFile != null) {
          if (mounted) {
            setState(() {
              _uploadStatusMessage = 'Uploading ingredient ${i + 1} of $totalIng...';
            });
          }
          ingImageUrl = await _storageService.uploadIngredientImage(
            file: entry.localImageFile!,
            onProgress: (progress) {
              if (mounted) {
                setState(() => _uploadProgress = 0.5 + ((i + progress) / totalIng) * 0.5);
              }
            },
          );
        }

        finalIngredients.add(
          IngredientItem(
            name: entry.nameController.text.trim(),
            amount: entry.amountController.text.trim(),
            image: ingImageUrl,
          ),
        );
      }

      // 3. Build Instructions list
      final instructions = _instructionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // 4. Create Recipe object
      final newRecipe = Recipe(
        id: recipeId,
        name: recipeName,
        calorie: _calorieController.text.trim(),
        category: _selectedCategory!,
        categoryId: _selectedCategory!.toLowerCase(),
        image: recipeImageUrl,
        rating: double.tryParse(_ratingController.text.trim()) ?? 4.8,
        review: int.tryParse(_reviewsController.text.trim()) ?? 0,
        time: int.tryParse(_timeController.text.trim()) ?? 25,
        isFavorite: false,
        isPublished: _isPublished,
        ingredients: finalIngredients,
        ingredientImage: finalIngredients.map((e) => e.image).toList(),
        ingredientName: finalIngredients.map((e) => e.name).toList(),
        ingredientAmount: finalIngredients.map((e) => e.amount).toList(),
        instructions: instructions,
        viewCount: 0,
        favoriteCount: 0,
      );

      setState(() => _uploadStatusMessage = 'Saving recipe to Firestore...');
      final success = await recipeProvider.createRecipe(newRecipe, uid);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "$recipeName" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(recipeProvider.errorMessage ?? 'Failed to create recipe.'),
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
    final recipeProvider = context.watch<RecipeProvider>();
    final categories = recipeProvider.categories.where((c) => c.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Image Picker
              Text(
                'Recipe Image *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _isLoading ? null : _pickRecipeImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: _recipeImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _recipeImageFile!.path,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Iconsax.image, size: 40),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Iconsax.edit, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                            Icon(Iconsax.image, size: 44, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Upload Recipe Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('JPG, PNG, WEBP • Max 5 MB', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                ),
              ),

              if (_uploadProgress > 0 && _uploadProgress < 1.0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_uploadStatusMessage, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ],

              const SizedBox(height: 24),

              // Basic Info Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Recipe Title *',
                  hintText: 'e.g. Creamy Garlic Butter Salmon',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat.name, child: Text(cat.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _calorieController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Calories (kcal)',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Time (minutes) *',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        if (val == null || int.tryParse(val.trim()) == null || int.parse(val.trim()) <= 0) {
                          return 'Positive integer';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ratingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Initial Rating (0–5)',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        final d = double.tryParse(val ?? '');
                        if (d == null || d < 0 || d > 5) return '0.0 to 5.0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reviewsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Review Count',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Ingredients Builder Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Ingredients (${_ingredientEntries.length})'),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    icon: const Icon(Iconsax.add_circle, size: 18),
                    label: const Text('Add Ingredient'),
                    onPressed: _addIngredient,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(_ingredientEntries.length, (index) {
                final entry = _ingredientEntries[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      // Ingredient Image Button
                      GestureDetector(
                        onTap: () => _pickIngredientImage(index),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: entry.localImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    entry.localImageFile!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Iconsax.image, size: 20),
                                  ),
                                )
                              : const Icon(Iconsax.gallery_add, size: 20, color: Colors.white60),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name Field
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: entry.nameController,
                          decoration: const InputDecoration(
                            hintText: 'Name (e.g. Onion)',
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Amount Field
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: entry.amountController,
                          decoration: const InputDecoration(
                            hintText: 'Amount (e.g. 2 pcs)',
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),

                      // Delete
                      if (_ingredientEntries.length > 1)
                        IconButton(
                          icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
                          onPressed: () => _removeIngredient(index),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 28),

              // Instructions Builder Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Cooking Steps (${_instructionControllers.length})'),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    icon: const Icon(Iconsax.add_circle, size: 18),
                    label: const Text('Add Step'),
                    onPressed: _addInstruction,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(_instructionControllers.length, (index) {
                final ctrl = _instructionControllers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Step ${index + 1} instruction description...',
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      if (_instructionControllers.length > 1)
                        IconButton(
                          icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
                          onPressed: () => _removeInstruction(index),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Published Status Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        Text('Publish Recipe Immediately', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Unpublished recipes are saved as drafts', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    Switch(
                      value: _isPublished,
                      activeThumbColor: Colors.greenAccent,
                      onChanged: (val) => setState(() => _isPublished = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Save Recipe Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _saveRecipe,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isPublished ? 'Create & Publish Recipe' : 'Save as Draft',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
