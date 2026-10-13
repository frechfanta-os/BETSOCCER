import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../widgets/match_card.dart';
import '../widgets/state_views.dart';

class HistoryScreen extends StatelessWidget {
  final SportsController controller;

  const HistoryScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final matches = controller.historicalMatches;

    if (matches.isEmpty) {
      return const EmptyStateView(
        title: 'Historique vide',
        message: 'Aucun match archivé n\'est disponible. Chargez les données OpenFootball dans les Paramètres.',
        icon: Icons.history_toggle_off_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return MatchCard(match: matches[index]);
      },
    );
  }
}
