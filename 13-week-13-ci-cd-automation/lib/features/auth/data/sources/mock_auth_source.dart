import '../models/auth_session_model.dart';

// Mock sesuai codelab. Ini bukan JWT terverifikasi atau Firebase Auth.
class MockAuthSource {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw const FormatException('Email atau kata sandi tidak valid.');
    }
    return AuthSessionModel(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!refreshToken.startsWith('mock-refresh-for-')) {
      throw const FormatException('Refresh token tidak valid.');
    }
    return 'mock-access-renewed-${DateTime.now().microsecondsSinceEpoch}';
  }
}
