import '../../domain/entities/auth_session.dart';

class AuthSessionModel {
  const AuthSessionModel({required this.access, required this.refresh});
  final String access;
  final String refresh;
  AuthSession toEntity() => AuthSession(access: access, refresh: refresh);
}
