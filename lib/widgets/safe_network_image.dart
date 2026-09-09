import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../utils/app_theme.dart';

class SafeNetworkImage extends StatelessWidget {
  SafeNetworkImage({
    super.key,
    String? url,
    String? imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : url = (imageUrl ?? url ?? '').trim();

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    Widget child;
    if (url.trim().isEmpty) {
      child = _placeholder(context);
    } else {
      child = Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return _loadingPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(context),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: child,
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.dividerColor,
      alignment: Alignment.center,
      child: Icon(
        Iconsax.reserve,
        color: theme.textTheme.bodyMedium?.color?.withAlpha(128) ??
            AppColors.textSecondary,
        size: 32,
      ),
    );
  }

  Widget _loadingPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.dividerColor,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
