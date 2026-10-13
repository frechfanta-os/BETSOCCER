/// Utilitaires de normalisation et d'affichage des dates en UTC strict
class AppDateUtils {
  AppDateUtils._();

  /// Parse une chaîne de caractères en DateTime UTC garanti
  static DateTime parseUtc(String isoString) {
    final parsed = DateTime.parse(isoString);
    return parsed.isUtc ? parsed : parsed.toUtc();
  }

  /// Formate une date en format ISO-8601 UTC standardisé
  static String formatIsoUtc(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  /// Affichage lisible pour l'utilisateur (date et heure locale)
  static String formatDisplay(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Affichage court de la date
  static String formatShortDate(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$day/$month/$year';
  }
}
