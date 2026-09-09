import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/image_url_validator.dart';
import '../../widgets/safe_network_image.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditIngredientFormEntry {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController imageController;

  _EditIngredientFormEntry({
    required String name,
    required String amount,
    String imageUrl = '',
  })  : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount),
        imageController = TextEditingController(text: imageUrl);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    imageController.dispose();
  }
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _imageController;
  late TextEditingController _calorieController;
  late TextEditingController _timeController;
  late TextEditingController _ratingController;
  late TextEditingController _reviewsController;

  late String _selectedCategory;
  late bool _isPublished;
  bool _isLoading = false;

  late List<_EditIngredientFormEntry> _ingredientEntries;
  late List<TextEditingController> _instructionControllers;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameController = TextEditingController(text: r.name);
    _imageController = TextEditingController(text: r.image);
    _calorieController = TextEditingController(text: r.calorie);
    _timeController = TextEditingController(text: r.time.toString());
    _ratingController = TextEditingController(text: r.rating.toString());
    _reviewsController = TextEditingController(text: r.review.toString());
    _selectedCategory = r.category;
    _isPublished = r.isPublished;

    _imageController.addListener(() {
      setState(() {});
    });

    // Initialize ingredients
    if (r.ingredients.isNotEmpty) {
      _ingredientEntries = r.ingredients
          .map((i) => _EditIngredientFormEntry(
                name: i.name,
                amount: i.amount,
                imageUrl: i.image,
              ))
          .toList();
    } else {
      _ingredientEntries = List.generate(
        r.safeIngredientCount,
        (i) => _EditIngredientFormEntry(
          name: r.ingredientName[i],
          amount: r.ingredientAmount[i],
          imageUrl: r.ingredientImage[i],
        ),
      );
    }
    if (_ingredientEntries.isEmpty) {
      _ingredientEntries.add(_EditIngredientFormEntry(name: '', amount: ''));
    }

    for (var entry in _ingredientEntries) {
      entry.imageController.addListener(() => setState(() {}));
    }

    // Initialize instructions
    if (r.instructions.isNotEmpty) {
      _instructionControllers = r.instructions
          .map((inst) => TextEditingController(text: inst))
          .toList();
    } else {
      _instructionControllers = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
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

  void _addIngredient() {
    setState(() {
      final entry = _EditIngredientFormEntry(name: '', amount: '');
      entry.imageController.addListener(() => setState(() {}));
      _ingredientEntries.add(entry);
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

  Future<void> _updateRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    final recipeImageUrl = _imageController.text.trim();
    if (_isPublished && recipeImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A published recipe must have an image URL provided.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final validIngredients = _ingredientEntries
        .where((e) =>
            e.nameController.text.trim().isNotEmpty &&
            e.amountController.text.trim().isNotEmpty)
        .toList();

    if (_isPublished && validIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please add at least one valid ingredient (name & amount required).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final recipeProvider = context.read<RecipeProvider>();

    setState(() => _isLoading = true);

    try {
      final finalIngredients = validIngredients.map((entry) {
        return IngredientItem(
          name: entry.nameController.text.trim(),
          amount: entry.amountController.text.trim(),
          image: entry.imageController.text.trim(),
        );
      }).toList();

      // Build Instructions list
      final instructions = _instructionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Update Recipe object
      final updatedRecipe = widget.recipe.copyWith(
        name: _nameController.text.trim(),
        calorie: _calorieController.text.trim(),
        category: _selectedCategory,
        categoryId: _selectedCategory.toLowerCase(),
        image: recipeImageUrl,
        rating: double.tryParse(_ratingController.text.trim()) ??
            widget.recipe.rating,
        review: int.tryParse(_reviewsController.text.trim()) ??
            widget.recipe.review,
        time: int.tryParse(_timeController.text.trim()) ?? widget.recipe.time,
        isPublished: _isPublished,
        ingredients: finalIngredients,
        ingredientImage: finalIngredients.map((e) => e.image).toList(),
        ingredientName: finalIngredients.map((e) => e.name).toList(),
        ingredientAmount: finalIngredients.map((e) => e.amount).toList(),
        instructions: instructions,
        searchName: _nameController.text.trim().toLowerCase(),
      );

      final success = await recipeProvider.updateRecipe(updatedRecipe);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(recipeProvider.errorMessage ?? 'Failed to update recipe.'),
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
    final categories =
        recipeProvider.categories.where((c) => c.isActive).toList();
    final previewUrl = _imageController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Image Preview Card
              Text(
                'Recipe Image Preview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white24, style: BorderStyle.solid),
                ),
                child: ImageUrlValidator.isValidHttpsImageUrl(previewUrl)
                    ? SafeNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(16),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.image,
                              size: 44, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text('Enter Recipe Image URL Below',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('HTTPS image preview will display here',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
              ),

              const SizedBox(height: 14),

              // Image URL Field
              Text(
                'Recipe Image URL (HTTPS) *',
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
                validator: (val) => ImageUrlValidator.validate(
                  val,
                  isRequired: _isPublished,
                  fieldName: 'Recipe Image URL',
                ),
              ),

              const SizedBox(height: 24),

              // Basic Info Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Recipe Title *',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 14),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: categories.any((c) => c.name == _selectedCategory)
                    ? _selectedCategory
                    : (categories.isNotEmpty ? categories.first.name : null),
                decoration: InputDecoration(
                  labelText: 'Category *',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                      value: cat.name, child: Text(cat.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                validator: (val) =>
                    val == null ? 'Please select a category' : null,
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        if (val == null ||
                            int.tryParse(val.trim()) == null ||
                            int.parse(val.trim()) <= 0) {
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Rating (0–5)',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
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
                  _buildSectionTitle(
                      'Ingredients (${_ingredientEntries.length})'),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
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
                              icon: const Icon(Iconsax.trash,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () => _removeIngredient(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: entry.imageController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'Optional Ingredient Image URL (HTTPS)',
                          isDense: true,
                          prefixIcon: Icon(Iconsax.image, size: 16),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (val) => ImageUrlValidator.validate(
                          val,
                          isRequired: false,
                          fieldName: 'Ingredient Image URL',
                        ),
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
                  _buildSectionTitle(
                      'Cooking Steps (${_instructionControllers.length})'),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
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
                        child: Text('${index + 1}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'Step ${index + 1} instruction description...',
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      if (_instructionControllers.length > 1)
                        IconButton(
                          icon: const Icon(Iconsax.trash,
                              size: 18, color: Colors.redAccent),
                          onPressed: () => _removeInstruction(index),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Published Status Switch
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
                        Text('Published Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Drafts are hidden from audience users',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
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

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _updateRecipe,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
