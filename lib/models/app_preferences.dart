import 'package:flutter/material.dart';

/// Immutable model representing all local preferences and layout settings,
/// serialized and stored in Firestore for each user.
class AppPreferences {
  const AppPreferences({
    this.themeMode = 'system',
    this.recipeRecommendations = true,
    this.newRecipes = true,
    this.cookingReminders = false,
    this.defaultServingQuantity = 1,
    this.showCalories = true,
    this.showCookingTime = true,
    this.caseInsensitiveSearch = true,
  });

  final String themeMode; // 'light', 'dark', 'system'
  final bool recipeRecommendations;
  final bool newRecipes;
  final bool cookingReminders;
  final int defaultServingQuantity;
  final bool showCalories;
  final bool showCookingTime;
  final bool caseInsensitiveSearch;

  /// Returns the corresponding Flutter [ThemeMode] enum.
  ThemeMode get activeThemeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  AppPreferences copyWith({
    String? themeMode,
    bool? recipeRecommendations,
    bool? newRecipes,
    bool? cookingReminders,
    int? defaultServingQuantity,
    bool? showCalories,
    bool? showCookingTime,
    bool? caseInsensitiveSearch,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      recipeRecommendations:
          recipeRecommendations ?? this.recipeRecommendations,
      newRecipes: newRecipes ?? this.newRecipes,
      cookingReminders: cookingReminders ?? this.cookingReminders,
      defaultServingQuantity:
          defaultServingQuantity ?? this.defaultServingQuantity,
      showCalories: showCalories ?? this.showCalories,
      showCookingTime: showCookingTime ?? this.showCookingTime,
      caseInsensitiveSearch:
          caseInsensitiveSearch ?? this.caseInsensitiveSearch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'recipeRecommendations': recipeRecommendations,
      'newRecipes': newRecipes,
      'cookingReminders': cookingReminders,
      'defaultServingQuantity': defaultServingQuantity,
      'showCalories': showCalories,
      'showCookingTime': showCookingTime,
      'caseInsensitiveSearch': caseInsensitiveSearch,
    };
  }

  factory AppPreferences.fromMap(Map<String, dynamic> map) {
    return AppPreferences(
      themeMode: map['themeMode'] as String? ?? 'system',
      recipeRecommendations: map['recipeRecommendations'] as bool? ?? true,
      newRecipes: map['newRecipes'] as bool? ?? true,
      cookingReminders: map['cookingReminders'] as bool? ?? false,
      defaultServingQuantity: map['defaultServingQuantity'] as int? ?? 1,
      showCalories: map['showCalories'] as bool? ?? true,
      showCookingTime: map['showCookingTime'] as bool? ?? true,
      caseInsensitiveSearch: map['caseInsensitiveSearch'] as bool? ?? true,
    );
  }
}
