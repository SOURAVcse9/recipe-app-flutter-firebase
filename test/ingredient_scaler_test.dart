import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/utils/ingredient_scaler.dart';

void main() {
  group('IngredientScaler.scale Tests', () {
    test('Scales basic integer amounts', () {
      expect(IngredientScaler.scale('400 g', 2), equals('800 g'));
      expect(IngredientScaler.scale('100 g', 3), equals('300 g'));
      expect(IngredientScaler.scale('2 tbsp', 3), equals('6 tbsp'));
    });

    test('Scales decimal values', () {
      expect(IngredientScaler.scale('1.5 cup', 2), equals('3 cup'));
      expect(IngredientScaler.scale('0.5 tsp', 3), equals('1.5 tsp'));
    });

    test('Scales fraction values', () {
      expect(IngredientScaler.scale('1/2 tsp', 2), equals('1 tsp'));
      expect(IngredientScaler.scale('3/4 cup', 2), equals('1.5 cup'));
    });

    test('Preserves text units and complex names', () {
      expect(IngredientScaler.scale('1 large onion', 2), equals('2 large onion'));
    });

    test('Preserves unparseable text without crashing', () {
      expect(IngredientScaler.scale('Salt to taste', 2), equals('Salt to taste'));
      expect(IngredientScaler.scale('as needed', 5), equals('as needed'));
      expect(IngredientScaler.scale('', 2), equals(''));
    });
  });
}
