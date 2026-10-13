import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../../../../core/theme/app_colors.dart';

class SportsScreen extends StatelessWidget {
  final SportsController controller;
  final VoidCallback onSelectDone;

  const SportsScreen({
    super.key,
    required this.controller,
    required this.onSelectDone,
  });

  @override
  Widget build(BuildContext context) {
    final sports = controller.sports;

    if (sports.isEmpty) {
      return const Center(
        child: Text(
          'Aucun sport disponible. Importez des données dans Paramètres.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sports.length,
      itemBuilder: (context, index) {
        final sport = sports[index];
        final isSelected = controller.selectedSport?.id == sport.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: isSelected ? AppColors.surfaceDark : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? AppColors.primary : Colors.white10,
              foregroundColor: isSelected ? Colors.black : Colors.white,
              child: const Icon(Icons.sports_soccer_rounded),
            ),
            title: Text(
              sport.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Code: ${sport.code} • Source: ${sport.sourceProvider}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryDark,
              ),
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                  ),
            onTap: () async {
              await controller.selectSport(sport);
              onSelectDone();
            },
          ),
        );
      },
    );
  }
}
