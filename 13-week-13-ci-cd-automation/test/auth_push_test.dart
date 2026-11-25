import 'package:campus_notify/app/data/api_client.dart';
import 'package:campus_notify/features/auth/data/sources/mock_auth_source.dart';
import 'package:campus_notify/app/data/mock_campus_adapter.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_notify/routes.dart';
import 'package:campus_notify/core/format.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/app/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_token_store.dart';

void main() {
  test('routeFromMessage menangani route kosong dan tanpa slash', () {
    expect(routeFromMessage({}), AppRoutes.home);
    expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    expect(routeFromMessage({'route': 'https://example.com'}), AppRoutes.home);
  });
  test('data payload membawa id pengumuman', () {
    const data = {'route': '/pengumuman/3', 'id': '3'};
    expect(data['id'], '3');
    expect(routeFromMessage(data), AppRoutes.announcement(data['id']!));
  });
  test(
    'provider auth membaca sesi tersimpan dan logout membersihkan token',
    () async {
      final store = FakeTokenStore();
      await store.save(
        access: 'mock-access',
        refresh: 'mock-refresh-for-demo@kampus.test',
      );
      final container = ProviderContainer(
        overrides: [tokenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      expect(await container.read(authStateProvider.future), isTrue);
      await container.read(authStateProvider.notifier).logout();
      expect(container.read(authStateProvider).value, isFalse);
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    },
  );
  test(
    '401 refresh sekali dan retry; refresh gagal membersihkan sesi',
    () async {
      final store = FakeTokenStore();
      await store.save(
        access: 'mock-access',
        refresh: 'mock-refresh-for-demo@kampus.test',
      );
      var expired = false;
      final dio = buildApiClient(
        store,
        MockAuthSource(),
        onSessionExpired: () async {
          expired = true;
        },
      );
      final adapter = MockCampusAdapter();
      dio.httpClientAdapter = adapter;
      addTearDown(() => dio.close());
      final response = await dio.get<dynamic>(
        '/profile',
        options: Options(extra: {'expireAccess': true}),
      );
      expect(response.statusCode, 200);
      expect(adapter.requests, 2);
      expect(expired, isFalse);
      await store.save(access: 'mock-access', refresh: '');
      await expectLater(
        dio.get<dynamic>(
          '/profile',
          options: Options(extra: {'expireAccess': true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(expired, isTrue);
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    },
  );
  test(
    'DI refresh gagal membersihkan sesi dan memperbarui auth state',
    () async {
      final store = FakeTokenStore();
      await store.save(access: 'mock-access', refresh: 'mock-refresh-for-demo');
      final container = ProviderContainer(
        overrides: [tokenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      expect(await container.read(authStateProvider.future), isTrue);
      final repository = container.read(authRepositoryProvider);
      final success = await repository.demoRefresh(failRefresh: false);
      expect(success.failure, isNull);
      expect(success.value, '401 → refresh sekali → retry 200');
      final failure = await repository.demoRefresh(failRefresh: true);
      expect(failure.failure, isA<SessionFailure>());
      expect(container.read(authStateProvider).value, isFalse);
      expect(store.access, isNull);
      expect(store.refresh, isNull);
    },
  );
}
