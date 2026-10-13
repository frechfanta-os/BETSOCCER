import '../../domain/entities/match.dart';

/// Modèle intermédiaire résultant du parsing OpenFootball
class ParsedOpenFootballMatch {
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final int? homeHalftimeScore;
  final int? awayHalftimeScore;
  final int matchday;
  final String roundLabel;
  final DateTime utcKickoff;
  final MatchStatus status;

  const ParsedOpenFootballMatch({
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.homeHalftimeScore,
    this.awayHalftimeScore,
    required this.matchday,
    required this.roundLabel,
    required this.utcKickoff,
    required this.status,
  });
}

/// Résultat complet du parsing d'un fichier Football.TXT
class ParsedOpenFootballDataset {
  final String competitionName;
  final String seasonLabel;
  final int startYear;
  final int endYear;
  final Set<String> teams;
  final List<ParsedOpenFootballMatch> matches;

  const ParsedOpenFootballDataset({
    required this.competitionName,
    required this.seasonLabel,
    required this.startYear,
    required this.endYear,
    required this.teams,
    required this.matches,
  });
}

/// Parser spécialisé pour le format standard Football.TXT (openfootball CC0)
class OpenFootballParser {
  static const Map<String, int> _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// Parse le contenu textuel complet d'un fichier Football.TXT
  static ParsedOpenFootballDataset parse(String rawText) {
    final lines = rawText.split('\n');

    String competitionName = 'Football League';
    String seasonLabel = '2023/24';
    int startYear = 2023;
    int endYear = 2024;

    int currentMatchday = 1;
    String currentRoundLabel = 'Matchday 1';
    int currentMonth = 8;
    int currentDay = 1;
    int currentHour = 15;
    int currentMinute = 0;

    final teams = <String>{};
    final matches = <ParsedOpenFootballMatch>[];

    // Regex pour détecter les lignes de match : Équipe A   X-Y [(x-y)]  Équipe B
    final matchRegex = RegExp(
      r'^\s*(?:(\d{1,2}:\d{2})\s+)?([A-Za-z0-9&.\-\s]+?)\s{2,}(\d+)-(\d+)(?:\s+\((\d+)-(\d+)\))?\s{2,}([A-Za-z0-9&.\-\s]+?)\s*$',
    );

    // Regex pour les matchs non joués / à venir : Équipe A   v   Équipe B
    final upcomingRegex = RegExp(
      r'^\s*(?:(\d{1,2}:\d{2})\s+)?([A-Za-z0-9&.\-\s]+?)\s{2,}v\s{2,}([A-Za-z0-9&.\-\s]+?)\s*$',
    );

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty || line.startsWith('#')) continue;

      // 1. En-tête de compétition : = English Premier League 2023/24
      if (line.startsWith('=')) {
        final title = line.replaceFirst('=', '').trim();
        final yearMatch = RegExp(r'(\d{4})(?:/(\d{2,4}))?').firstMatch(title);
        if (yearMatch != null) {
          startYear = int.parse(yearMatch.group(1)!);
          if (yearMatch.group(2) != null) {
            final part = yearMatch.group(2)!;
            endYear = part.length == 2
                ? (startYear - (startYear % 100)) + int.parse(part)
                : int.parse(part);
            seasonLabel = '$startYear/${yearMatch.group(2)}';
          } else {
            endYear = startYear;
            seasonLabel = '$startYear';
          }
          competitionName = title.replaceAll(yearMatch.group(0)!, '').trim();
        } else {
          competitionName = title;
        }
        continue;
      }

      // 2. Détection de journée : ▪ Matchday 1
      if (line.contains('Matchday') ||
          line.contains('Round') ||
          line.contains('Journée')) {
        final m = RegExp(r'(?:Matchday|Round|Journée)\s*(\d+)')
            .firstMatch(line);
        if (m != null) {
          currentMatchday = int.parse(m.group(1)!);
          currentRoundLabel = 'Journée $currentMatchday';
        }
        continue;
      }

      // 3. Détection de date : Fri Aug 11
      final dateMatch = RegExp(
        r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s+([A-Za-z]{3})\s+(\d{1,2})',
      ).firstMatch(line.trim());
      if (dateMatch != null) {
        final mStr = dateMatch.group(1)!.toLowerCase();
        if (_months.containsKey(mStr)) {
          currentMonth = _months[mStr]!;
          currentDay = int.parse(dateMatch.group(2)!);
          currentHour = 15;
          currentMinute = 0;
        }
        continue;
      }

      // 4. Ligne de match joué avec score
      final matchMatch = matchRegex.firstMatch(line);
      if (matchMatch != null) {
        final timeStr = matchMatch.group(1);
        if (timeStr != null) {
          final timeParts = timeStr.split(':');
          currentHour = int.parse(timeParts[0]);
          currentMinute = int.parse(timeParts[1]);
        }

        final homeTeam = matchMatch.group(2)!.trim();
        final homeScore = int.parse(matchMatch.group(3)!);
        final awayScore = int.parse(matchMatch.group(4)!);
        final htHome = matchMatch.group(5) != null
            ? int.parse(matchMatch.group(5)!)
            : null;
        final htAway = matchMatch.group(6) != null
            ? int.parse(matchMatch.group(6)!)
            : null;
        final awayTeam = matchMatch.group(7)!.trim();

        teams.add(homeTeam);
        teams.add(awayTeam);

        // Détermination de l'année selon le mois
        final matchYear = (currentMonth >= 8 || startYear == endYear)
            ? startYear
            : endYear;
        final kickoff = DateTime.utc(
          matchYear,
          currentMonth,
          currentDay,
          currentHour,
          currentMinute,
        );

        matches.add(
          ParsedOpenFootballMatch(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: homeScore,
            awayScore: awayScore,
            homeHalftimeScore: htHome,
            awayHalftimeScore: htAway,
            matchday: currentMatchday,
            roundLabel: currentRoundLabel,
            utcKickoff: kickoff,
            status: MatchStatus.finished,
          ),
        );
        continue;
      }

      // 5. Ligne de match à venir (sans score)
      final upMatch = upcomingRegex.firstMatch(line);
      if (upMatch != null) {
        final timeStr = upMatch.group(1);
        if (timeStr != null) {
          final timeParts = timeStr.split(':');
          currentHour = int.parse(timeParts[0]);
          currentMinute = int.parse(timeParts[1]);
        }
        final homeTeam = upMatch.group(2)!.trim();
        final awayTeam = upMatch.group(3)!.trim();

        teams.add(homeTeam);
        teams.add(awayTeam);

        final matchYear = (currentMonth >= 8 || startYear == endYear)
            ? startYear
            : endYear;
        final kickoff = DateTime.utc(
          matchYear,
          currentMonth,
          currentDay,
          currentHour,
          currentMinute,
        );

        matches.add(
          ParsedOpenFootballMatch(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            matchday: currentMatchday,
            roundLabel: currentRoundLabel,
            utcKickoff: kickoff,
            status: MatchStatus.upcoming,
          ),
        );
      }
    }

    return ParsedOpenFootballDataset(
      competitionName: competitionName,
      seasonLabel: seasonLabel,
      startYear: startYear,
      endYear: endYear,
      teams: teams,
      matches: matches,
    );
  }
}
