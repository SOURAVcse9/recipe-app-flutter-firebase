/// Parses strings like "400 g", "2 tbsp", "1kg", "500ml" into a numeric
/// value + unit, and re-composes them after scaling by a quantity factor.
///
/// If a string can't be safely parsed (e.g. "a pinch", "to taste"), the
/// original text is returned unchanged instead of throwing or guessing.
class IngredientScaler {
  IngredientScaler._();

  // Matches an optional leading number (int or decimal, incl. simple
  // fractions like "1/2") followed by an optional unit/word.
  static final RegExp _pattern = RegExp(
    r'^\s*([0-9]+(?:\.[0-9]+)?(?:\s*/\s*[0-9]+)?)\s*(.*)$',
  );

  /// Scales a single ingredient amount string by [quantity].
  ///
  /// Example: scale("400 g", 2) -> "800 g"
  ///          scale("2 tbsp", 3) -> "6 tbsp"
  ///          scale("a pinch", 2) -> "a pinch" (unparseable, preserved)
  static String scale(String amount, int quantity) {
    if (amount.trim().isEmpty || quantity <= 0) return amount;

    final match = _pattern.firstMatch(amount.trim());
    if (match == null) return amount;

    final numericPart = match.group(1);
    final unitPart = match.group(2) ?? '';

    if (numericPart == null) return amount;

    final baseValue = _parseNumeric(numericPart);
    if (baseValue == null) return amount;

    final scaledValue = baseValue * quantity;
    final formattedValue = _formatNumber(scaledValue);
    final trimmedUnit = unitPart.trim();

    return trimmedUnit.isEmpty
        ? formattedValue
        : '$formattedValue $trimmedUnit';
  }

  /// Parses "400", "2.5", or "1/2" into a double. Returns null if it can't
  /// be interpreted as a number at all.
  static double? _parseNumeric(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      if (parts.length != 2) return null;
      final numerator = double.tryParse(parts[0].trim());
      final denominator = double.tryParse(parts[1].trim());
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      return numerator / denominator;
    }
    return double.tryParse(trimmed);
  }

  /// Formats a scaled number without an unnecessary trailing ".0".
  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    // Keep up to 2 decimal places, trimming trailing zeros.
    String formatted = value.toStringAsFixed(2);
    formatted = formatted.replaceFirst(RegExp(r'0+$'), '');
    formatted = formatted.replaceFirst(RegExp(r'\.$'), '');
    return formatted;
  }
}
