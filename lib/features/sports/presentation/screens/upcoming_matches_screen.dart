import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../widgets/match_card.dart';
import '../widgets/state_views.dart';

class UpcomingMatchesScreen extends StatelessWidget {
  final SportsController controller;

  const UpcomingMatchesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final matches = controller.upcomingMatches;

    if (matches.isEmpty) {
      return const EmptyStateView(
        title: 'Aucune rencontre à venir',
        message: 'Aucun match futur n\'est actuellement programmé dans le calendrier local.',
        icon: Icons.event_busy_rounded,
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
