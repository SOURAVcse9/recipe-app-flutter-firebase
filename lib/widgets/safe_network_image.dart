import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../utils/app_theme.dart';

/// A network image that never breaks the layout: shows a loading
/// placeholder while fetching, and a food-icon fallback if the URL is
/// empty, invalid, or fails to load. See IMAGE ERROR HANDLING in spec.
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    Widget child;
    if (url.trim().isEmpty) {
      child = _placeholder();
    } else {
      child = Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return _loadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: child,
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.chipUnselected,
      alignment: Alignment.center,
      child: const Icon(
        Iconsax.reserve,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      color: AppColors.chipUnselected,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
