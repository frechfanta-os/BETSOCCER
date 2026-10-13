// Modèle représentant les résultats d'estimation probabiliste d'un match.

enum EstimationStatus {
  confirmed, // Échantillon suffisant (>= 5 matchs par équipe)
  shrinkageEstimation, // Échantillon faible régularisé (1 à 4 matchs)
  insufficientData, // Données insuffisantes pour produire une estimation personnalisée
  unsupportedSportModel, // Modèle non transposable ou invalide pour ce sport
}

class MatchPredictionResult {
  final String matchId;
  final String homeTeamName;
  final String awayTeamName;
  final String sportId;
  final EstimationStatus status;
  final String method;

  // Probabilités normalisées (somme = 1.0)
  final double homeWinProb;
  final double drawProb; // 0.0 si sport sans nul (ex: tennis, basket)
  final double awayWinProb;

  // Espérance de buts / points (si applicable)
  final double? expectedHomeScore;
  final double? expectedAwayScore;
  final String? mostLikelyScore; // ex: "2-1"

  // Métadonnées temporelles et d'échantillon
  final int totalMatchesAnalyzed;
  final int homeTeamMatchesCount;
  final int awayTeamMatchesCount;
  final DateTime? temporalCutoff; // Prouve l'absence de fuite temporelle

  // Quantification de l'incertitude
  final double confidenceScore; // [0.0 - 1.0]
  final double entropy; // Entropie de Shannon normalisée

  // Avertissement et transparence
  final String disclaimer;

  const MatchPredictionResult({
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.sportId,
    required this.status,
    required this.method,
    required this.homeWinProb,
    required this.drawProb,
    required this.awayWinProb,
    this.expectedHomeScore,
    this.expectedAwayScore,
    this.mostLikelyScore,
    required this.totalMatchesAnalyzed,
    required this.homeTeamMatchesCount,
    required this.awayTeamMatchesCount,
    this.temporalCutoff,
    required this.confidenceScore,
    required this.entropy,
    this.disclaimer = 'Les probabilités calculées sont des estimations mathématiques indicatives fondées sur l\'historique disponible et ne constituent en aucun cas une certitude ou un conseil financier.',
  });

  /// Usine de refus pour sport non pris en charge
  factory MatchPredictionResult.unsupportedSport({
    required String matchId,
    required String homeTeamName,
    required String awayTeamName,
    required String sportId,
    required String reason,
  }) {
    return MatchPredictionResult(
      matchId: matchId,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      sportId: sportId,
      status: EstimationStatus.unsupportedSportModel,
      method: 'Sport Guardrail ($sportId)',
      homeWinProb: 0.0,
      drawProb: 0.0,
      awayWinProb: 0.0,
      totalMatchesAnalyzed: 0,
      homeTeamMatchesCount: 0,
      awayTeamMatchesCount: 0,
      confidenceScore: 0.0,
      entropy: 0.0,
      disclaimer: 'Modèle refusé : $reason',
    );
  }

  /// Usine de refus pour échantillon insuffisant (Cold start total)
  factory MatchPredictionResult.insufficientData({
    required String matchId,
    required String homeTeamName,
    required String awayTeamName,
    required String sportId,
    required int totalMatchesAnalyzed,
    required int homeTeamCount,
    required int awayTeamCount,
  }) {
    return MatchPredictionResult(
      matchId: matchId,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      sportId: sportId,
      status: EstimationStatus.insufficientData,
      method: 'Insufficient Data Guardrail',
      homeWinProb: 0.0,
      drawProb: 0.0,
      awayWinProb: 0.0,
      totalMatchesAnalyzed: totalMatchesAnalyzed,
      homeTeamMatchesCount: homeTeamCount,
      awayTeamMatchesCount: awayTeamCount,
      confidenceScore: 0.0,
      entropy: 0.0,
      disclaimer: 'Échantillon historique insuffisant pour produire une estimation statistique fiable.',
    );
  }

  bool get isReliable =>
      status == EstimationStatus.confirmed ||
      status == EstimationStatus.shrinkageEstimation;
}
