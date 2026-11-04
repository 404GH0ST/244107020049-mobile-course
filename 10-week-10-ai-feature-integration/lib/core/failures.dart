sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class SessionFailure extends Failure {
  const SessionFailure(super.message);
}

typedef Result<T> = ({T? value, Failure? failure});
String failureMessage(Object error) =>
    error is Failure ? error.message : 'Terjadi kesalahan. Silakan coba lagi.';
