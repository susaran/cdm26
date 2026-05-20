sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

class LeagueException extends AppException {
  const LeagueException(super.message);
}

class PredictionException extends AppException {
  const PredictionException(super.message);
}

class TeamException extends AppException {
  const TeamException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
