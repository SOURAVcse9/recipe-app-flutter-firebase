import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../utils/app_theme.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 20,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isFavorite ? Iconsax.heart5 : Iconsax.heart,
          size: size,
          color: isFavorite ? AppColors.heart : AppColors.textSecondary,
        ),
      ),
    );
  }
}
