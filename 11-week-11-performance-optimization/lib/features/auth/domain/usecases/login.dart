import '../../../../core/failures.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);
  final AuthRepository _repository;
  Future<Result<bool>> call({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim();
    if (!normalized.contains('@') || password.length < 6) {
      return (
        value: null,
        failure: const ValidationFailure('Email atau kata sandi tidak valid.'),
      );
    }
    final result = await _repository.login(
      email: normalized,
      password: password,
    );
    if (result.failure != null) return (value: null, failure: result.failure);
    final session = result.value;
    if (session == null) {
      return (
        value: null,
        failure: const SessionFailure('Login gagal. Silakan coba lagi.'),
      );
    }
    final saved = await _repository.saveSession(session);
    return (value: saved.failure == null ? true : null, failure: saved.failure);
  }
}
