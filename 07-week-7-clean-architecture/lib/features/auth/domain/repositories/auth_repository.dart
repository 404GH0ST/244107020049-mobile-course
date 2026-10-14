import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });
  Future<Result<bool>> restoreSession();
  Future<Result<void>> saveSession(AuthSession session);
  Future<Result<void>> logout();
  Future<Result<String>> demoRefresh({required bool failRefresh});
}
