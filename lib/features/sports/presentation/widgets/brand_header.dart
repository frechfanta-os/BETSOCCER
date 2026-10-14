import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// En-tête de marque BETSOCCER avec logo officiel, sous-titre et actions
class BrandHeader extends StatelessWidget {
  final String? customTitle;
  final String? subtitle;
  final Widget? trailingBadge;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  const BrandHeader({
    super.key,
    this.customTitle,
    this.subtitle,
    this.trailingBadge,
    this.onSearchTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Logo officiel de l'application BETSOCCER
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonLime.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.neonLime,
                  child: const Center(
                    child: Icon(
                      Icons.sports_soccer_rounded,
                      size: 22,
                      color: Color(0xFF0A111F),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Titre et sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      customTitle ?? 'BETSOCCER',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (trailingBadge != null) ...[
                      const SizedBox(width: 8),
                      trailingBadge!,
                    ],
                  ],
                ),
                Text(
                  subtitle ?? 'Live Matches • Fixtures • Stats',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Bouton Recherche
          IconButton(
            icon: Icon(Icons.search_rounded, color: primaryTextColor, size: 22),
            onPressed: onSearchTap ?? () {},
            tooltip: 'Recherche',
            visualDensity: VisualDensity.compact,
          ),

          // Bouton Notifications avec pastille rouge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: primaryTextColor,
                  size: 22,
                ),
                onPressed: onNotificationTap ?? () {},
                tooltip: 'Notifications',
                visualDensity: VisualDensity.compact,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.liveRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
