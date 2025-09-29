import 'package:stagess_common/exceptions.dart';

class ConnexionRefusedException implements InternshipBankException {
  final String _message;

  ConnexionRefusedException(String message) : _message = message;

  @override
  String toString() => _message;
}

class RateLimitedException implements InternshipBankException {
  RateLimitedException();

  @override
  String toString() => 'Rate limit exceeded';
}

class InvalidRequestTypeException implements InternshipBankException {
  final String _message;

  InvalidRequestTypeException(String message) : _message = message;

  @override
  String toString() => _message;
}

class MissingFieldException implements InternshipBankException {
  final String _message;

  MissingFieldException(String message) : _message = message;

  @override
  String toString() => _message;
}

class MissingDataException implements InternshipBankException {
  final String _message;

  MissingDataException(String message) : _message = message;

  @override
  String toString() => _message;
}

class InvalidRequestException implements InternshipBankException {
  final String _message;

  InvalidRequestException(String message) : _message = message;

  @override
  String toString() => _message;
}

class DatabaseFailureException implements InternshipBankException {
  final String _message;
// coverage:ignore-start
  DatabaseFailureException(String message) : _message = message;

  @override
  String toString() => _message;
// coverage:ignore-end
}
