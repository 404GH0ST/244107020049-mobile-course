import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../../../app/data/failure_mapper.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../sources/mock_auth_source.dart';
import '../sources/token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.source,
    required this.store,
    required this.dio,
  });
  final MockAuthSource source;
  final TokenStore store;
  final Dio dio;
  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      return (
        value: (await source.login(
          email: email,
          password: password,
        )).toEntity(),
        failure: null,
      );
    } catch (error) {
      return (
        value: null,
        failure: error is FormatException
            ? const ValidationFailure('Email atau kata sandi tidak valid.')
            : mapDataFailure(error),
      );
    }
  }

  @override
  Future<Result<bool>> restoreSession() async {
    try {
      final access = await store.readAccess();
      final refresh = await store.readRefresh();
      return (
        value:
            access != null &&
            access.isNotEmpty &&
            refresh != null &&
            refresh.isNotEmpty,
        failure: null,
      );
    } catch (_) {
      return (
        value: null,
        failure: const LocalFailure(
          'Gagal membaca sesi tersimpan. Silakan login kembali.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> saveSession(AuthSession session) async {
    try {
      await store.save(access: session.access, refresh: session.refresh);
      return (value: null, failure: null);
    } catch (_) {
      // Jangan meninggalkan separuh sesi jika penulisan kedua gagal.
      try {
        await store.clear();
      } catch (_) {}
      return (
        value: null,
        failure: const LocalFailure('Gagal menyimpan sesi. Silakan coba lagi.'),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await store.clear();
      return (value: null, failure: null);
    } catch (_) {
      return (
        value: null,
        failure: const LocalFailure('Gagal menghapus sesi. Silakan coba lagi.'),
      );
    }
  }

  @override
  Future<Result<String>> demoRefresh({required bool failRefresh}) async {
    try {
      if (failRefresh) {
        await store.save(access: (await store.readAccess()) ?? '', refresh: '');
      }
      final response = await dio.get<Map<String, dynamic>>(
        '/profile',
        options: Options(extra: {'expireAccess': true}),
      );
      return (
        value: response.data?['message'] as String? ?? 'Sukses',
        failure: null,
      );
    } catch (error) {
      return (value: null, failure: mapDataFailure(error));
    }
  }
}
