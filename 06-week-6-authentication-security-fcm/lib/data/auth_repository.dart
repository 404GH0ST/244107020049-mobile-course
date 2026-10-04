class AuthSession {
  const AuthSession({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

// Mock sesuai codelab. Ini bukan JWT terverifikasi atau Firebase Auth.
class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw const FormatException('Email atau kata sandi tidak valid.');
    }
    return AuthSession(
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
