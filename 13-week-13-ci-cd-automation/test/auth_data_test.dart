import 'package:campus_notify/app/data/api_client.dart';
import 'package:campus_notify/app/data/failure_mapper.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campus_notify/features/auth/data/sources/mock_auth_source.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_token_store.dart';

class BrokenReadStore extends FakeTokenStore {
  @override
  Future<String?> readAccess() async =>
      throw StateError('native internal secret');
}

class PartialWriteStore extends FakeTokenStore {
  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    throw StateError('native internal secret');
  }
}

void main() {
  test(
    'gagal baca storage menyelesaikan request, bukan menggantung interceptor',
    () async {
      final dio = buildApiClient(
        BrokenReadStore(),
        MockAuthSource(),
        onSessionExpired: () async {},
      );
      addTearDown(dio.close);
      try {
        await dio.get<dynamic>('/profile').timeout(const Duration(seconds: 2));
        fail('Request seharusnya gagal');
      } on DioException catch (error) {
        final failure = mapDataFailure(error);
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, isNot(contains('native internal secret')));
      }
    },
  );

  test(
    'penulisan token parsial dibersihkan dan tidak menjadi sesi sukses',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final store = PartialWriteStore();
      final repo = AuthRepositoryImpl(
        source: MockAuthSource(),
        store: store,
        dio: dio,
      );
      final result = await repo.saveSession(
        const AuthSession(access: 'access', refresh: 'refresh'),
      );
      expect(result.failure, isA<LocalFailure>());
      expect(store.access, isNull);
      expect(store.refresh, isNull);
      expect(
        result.failure!.message,
        isNot(contains('native internal secret')),
      );
    },
  );
}
