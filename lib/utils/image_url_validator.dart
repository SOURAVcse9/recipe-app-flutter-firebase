/// Utility class for validating external HTTPS image URLs.
/// Complies with Firebase Spark Plan requirements (Firestore-only external CDN image URLs).
class ImageUrlValidator {
  ImageUrlValidator._();

  static final List<String> _disallowedHosts = [
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '::1',
  ];

  static final List<String> _disallowedSuffixes = [
    '.local',
    '.internal',
    '.lan',
  ];

  /// Checks if a given string is a valid HTTPS image URL.
  ///
  /// Returns `true` if [url] is a valid HTTPS URL with a permissible public host.
  /// Rejects `http://`, `file://`, `data:`, `blob:`, `javascript:`, localhost, and IP loops.
  static bool isValidHttpsImageUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed.length < 8 || trimmed.length > 2048) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return false;
    }

    // Must be strictly HTTPS
    if (uri.scheme.toLowerCase() != 'https') {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host.isEmpty) {
      return false;
    }

    // Disallow localhost and private loopbacks
    if (_disallowedHosts.contains(host)) {
      return false;
    }

    for (final suffix in _disallowedSuffixes) {
      if (host.endsWith(suffix)) {
        return false;
      }
    }

    // Host must contain at least one dot or be a valid domain structure (unless localhost which is disallowed)
    if (!host.contains('.')) {
      return false;
    }

    return true;
  }

  /// Form field validator for image URLs.
  ///
  /// If [isRequired] is false (default), null or empty string returns null (valid).
  /// If provided or required, ensures the string is a valid HTTPS URL.
  static String? validate(
    String? value, {
    bool isRequired = false,
    String fieldName = 'Image URL',
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) {
        return '$fieldName is required';
      }
      return null;
    }

    final trimmed = value.trim();

    if (trimmed.length < 8) {
      return '$fieldName is too short';
    }

    if (trimmed.length > 2048) {
      return '$fieldName is too long (maximum 2048 characters)';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return 'Please enter a valid URL (e.g. https://...)';
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https') {
      if (scheme == 'http') {
        return 'Insecure HTTP not supported. Please use HTTPS (https://...)';
      }
      return 'Only HTTPS URLs are supported (https://...)';
    }

    final host = uri.host.toLowerCase();
    if (host.isEmpty) {
      return 'Invalid domain in $fieldName';
    }

    if (_disallowedHosts.contains(host) ||
        _disallowedSuffixes.any((s) => host.endsWith(s))) {
      return 'Local/private network URLs are not allowed';
    }

    if (!host.contains('.')) {
      return 'Please enter a valid domain name (e.g. example.com)';
    }

    return null;
  }

  /// Helper to verify if an image URL is safe and valid for live preview rendering.
  static bool isSafePreviewUrl(String? url) {
    return isValidHttpsImageUrl(url);
  }
}
