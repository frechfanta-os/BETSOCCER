import 'package:flutter/material.dart';

import '../controllers/sports_controller.dart';
import '../widgets/match_card.dart';
import '../widgets/state_views.dart';

class LiveMatchesScreen extends StatelessWidget {
  final SportsController controller;

  const LiveMatchesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final matches = controller.liveMatches;

    if (matches.isEmpty) {
      return EmptyStateView(
        title: 'Aucun match en direct',
        message: 'Il n\'y a actuellement aucune rencontre en cours de jeu sur les ligues suivies.',
        icon: Icons.sensors_off_rounded,
        actionLabel: 'Rafraîchir les scores',
        onAction: () => controller.refreshLiveMatches(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refreshLiveMatches(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return MatchCard(match: matches[index]);
        },
      ),
    );
  }
}
