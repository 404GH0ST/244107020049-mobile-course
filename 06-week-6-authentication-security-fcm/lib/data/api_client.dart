import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  required Future<void> Function() onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'CAMPUS_API_URL',
        defaultValue: 'https://example-campus-api.test',
      ),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  Future<String>? refreshing;
  Future<String> renew() async {
    final refresh = await store.readRefresh();
    if (refresh == null || refresh.isEmpty) throw StateError('Sesi berakhir');
    final access = await auth.refresh(refresh);
    await store.save(access: access, refresh: refresh);
    return access;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) options.headers['Authorization'] = 'Bearer $access';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) return handler.next(error);
        if (error.requestOptions.extra['authRetried'] == true) {
          await store.clear();
          await onSessionExpired();
          return handler.next(error);
        }
        String access;
        try {
          // Share satu refresh untuk request 401 yang datang bersamaan.
          final active = refreshing ??= renew();
          try {
            access = await active;
          } finally {
            if (identical(refreshing, active)) refreshing = null;
          }
        } catch (_) {
          await store.clear();
          await onSessionExpired();
          return handler.next(error);
        }
        try {
          final request = error.requestOptions.copyWith(
            headers: {
              ...error.requestOptions.headers,
              'Authorization': 'Bearer $access',
            },
            extra: {...error.requestOptions.extra, 'authRetried': true},
          );
          handler.resolve(await dio.fetch<dynamic>(request));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    ),
  );
  return dio;
}
