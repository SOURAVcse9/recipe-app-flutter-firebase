import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/widgets/quantity_selector.dart';

void main() {
  testWidgets('QuantitySelector displays quantity and triggers callbacks',
      (WidgetTester tester) async {
    int quantity = 2;
    bool incrementCalled = false;
    bool decrementCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuantitySelector(
            quantity: quantity,
            onIncrement: () => incrementCalled = true,
            onDecrement: () => decrementCalled = true,
          ),
        ),
      ),
    );

    // Verify initial quantity is shown
    expect(find.text('2'), findsOneWidget);

    // Tap increment and verify callback
    await tester.tap(find.byIcon(Iconsax.add));
    await tester.pump();
    expect(incrementCalled, isTrue);

    // Tap decrement and verify callback
    await tester.tap(find.byIcon(Iconsax.minus));
    await tester.pump();
    expect(decrementCalled, isTrue);
  });
}
