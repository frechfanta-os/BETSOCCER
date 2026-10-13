import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../../../../core/theme/app_colors.dart';

class CompetitionsScreen extends StatelessWidget {
  final SportsController controller;
  final VoidCallback onSelectDone;

  const CompetitionsScreen({
    super.key,
    required this.controller,
    required this.onSelectDone,
  });

  @override
  Widget build(BuildContext context) {
    final comps = controller.competitions;

    if (comps.isEmpty) {
      return const Center(
        child: Text('Aucune compétition disponible pour le sport sélectionné.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: comps.length,
      itemBuilder: (context, index) {
        final comp = comps[index];
        final isSelected = controller.selectedCompetition?.id == comp.id;

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
              child: const Icon(Icons.emoji_events_rounded),
            ),
            title: Text(
              comp.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Pays: ${comp.country ?? "International"} • Source: ${comp.sourceProvider}',
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
              await controller.selectCompetition(comp);
              onSelectDone();
            },
          ),
        );
      },
    );
  }
}
