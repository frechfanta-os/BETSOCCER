/// Classe de base des exceptions typées de BETSOCCER
sealed class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Erreur de connectivité ou réseau
class NetworkException extends AppException {
  final int? statusCode;
  const NetworkException(super.message, [this.statusCode, super.cause]);
}

/// Dépassement de quota ou limitation de débit (HTTP 429)
class RateLimitException extends AppException {
  final Duration? retryAfter;
  const RateLimitException(super.message, [this.retryAfter, super.cause]);
}

/// Erreur d'authentification ou clé API manquante/invalide
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.cause]);
}

/// Fonctionnalité non prise en charge par le fournisseur de données
class UnsupportedFeatureException extends AppException {
  final String providerId;
  final String feature;
  const UnsupportedFeatureException({
    required this.providerId,
    required this.feature,
    String? message,
  }) : super(
         message ??
             'Feature "$feature" is not supported by provider "$providerId".',
       );
}

/// Connecteur désactivé pour des raisons de conformité légale ou de politique de sécurité
class ConnectorDisabledException extends AppException {
  final String providerId;
  final String reason;
  const ConnectorDisabledException({
    required this.providerId,
    required this.reason,
  }) : super('Connector "$providerId" is disabled: $reason');
}

/// Erreur d'accès ou d'intégrité de la base de données locale SQLite
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.cause]);
}

/// Erreur de syntaxe ou parsing de données
class ParsingException extends AppException {
  const ParsingException(super.message, [super.cause]);
}
