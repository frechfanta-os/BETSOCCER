import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SportsSelectorBar extends StatelessWidget {
  final String selectedSport;
  final ValueChanged<String> onSportSelected;

  const SportsSelectorBar({
    super.key,
    required this.selectedSport,
    required this.onSportSelected,
  });

  static const List<Map<String, dynamic>> _sportItems = [
    {'label': 'All', 'icon': Icons.sports_rounded},
    {'label': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Basketball', 'icon': Icons.sports_basketball_rounded},
    {'label': 'Tennis', 'icon': Icons.sports_tennis_rounded},
    {'label': 'Handball', 'icon': Icons.sports_handball_rounded},
    {'label': 'Volleyball', 'icon': Icons.sports_volleyball_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveBg = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceElevatedLight;
    final inactiveText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final inactiveIcon = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: _sportItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _sportItems[index];
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = selectedSport.toLowerCase() == label.toLowerCase();

          return InkWell(
            onTap: () => onSportSelected(label),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonLime : inactiveBg,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.neonLime.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? AppColors.onNeonLime : inactiveIcon,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.onNeonLime : inactiveText,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
