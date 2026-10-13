import 'app_exception.dart';

/// Représentation des erreurs destinées à la couche présentation / UI
class Failure {
  final String title;
  final String message;
  final AppException? exception;

  const Failure({required this.title, required this.message, this.exception});

  factory Failure.fromException(AppException exception) {
    return switch (exception) {
      NetworkException(message: final msg) => Failure(
        title: 'Erreur réseau',
        message: msg,
        exception: exception,
      ),
      RateLimitException(message: final msg) => Failure(
        title: 'Quota dépassé',
        message: msg,
        exception: exception,
      ),
      AuthenticationException(message: final msg) => Failure(
        title: 'Authentification requise',
        message: msg,
        exception: exception,
      ),
      UnsupportedFeatureException(
        feature: final feat,
        providerId: final prov,
      ) =>
        Failure(
          title: 'Fonctionnalité non disponible',
          message: 'La source "$prov" ne fournit pas la fonction "$feat".',
          exception: exception,
        ),
      ConnectorDisabledException(reason: final r) => Failure(
        title: 'Connecteur désactivé',
        message: r,
        exception: exception,
      ),
      DatabaseException(message: final msg) => Failure(
        title: 'Erreur de base de données',
        message: msg,
        exception: exception,
      ),
      ParsingException(message: final msg) => Failure(
        title: 'Erreur de format de données',
        message: msg,
        exception: exception,
      ),
    };
  }

  @override
  String toString() => '$title: $message';
}
