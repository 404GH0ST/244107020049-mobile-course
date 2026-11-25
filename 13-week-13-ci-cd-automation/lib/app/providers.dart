// Composition root: satu tempat yang mengetahui implementasi data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/sources/mock_auth_source.dart';
import '../features/auth/data/sources/token_store.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login.dart';
import 'session_expiry.dart';
import '../features/announcements/data/sources/announcement_source.dart';
import '../features/announcements/data/repositories/announcement_repository_impl.dart';
import '../features/announcements/domain/repositories/announcement_repository.dart';
import '../features/announcements/domain/usecases/get_announcement.dart';
import '../features/push/data/services/push_service.dart';
import '../features/push/data/repositories/device_repository_impl.dart';
import '../features/push/domain/repositories/device_repository.dart';
import '../features/push/domain/repositories/push_repository.dart';
import 'data/api_client.dart';
import 'data/mock_campus_adapter.dart';

const useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: true);
final firebaseReadyProvider = Provider<bool>((ref) => false);
final tokenStoreProvider = Provider((ref) => TokenStore());
final mockAuthSourceProvider = Provider((ref) => MockAuthSource());
final mockCampusProvider = Provider((ref) => MockCampusAdapter());
final apiClientProvider = Provider((ref) {
  final dio = buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(mockAuthSourceProvider),
    onSessionExpired: () async {
      ref.read(sessionExpiryProvider.notifier).expire();
    },
  );
  if (useMockApi) dio.httpClientAdapter = ref.watch(mockCampusProvider);
  ref.onDispose(() => dio.close());
  return dio;
});
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    source: ref.watch(mockAuthSourceProvider),
    store: ref.watch(tokenStoreProvider),
    dio: ref.watch(apiClientProvider),
  ),
);
final loginProvider = Provider(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);
final announcementSourceProvider = Provider((ref) => AnnouncementSource());
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(ref.watch(announcementSourceProvider)),
);
final getAnnouncementProvider = Provider(
  (ref) => GetAnnouncement(ref.watch(announcementRepositoryProvider)),
);
final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepositoryImpl(ref.watch(apiClientProvider)),
);
final pushRepositoryProvider = Provider<PushRepository>((ref) {
  final service = PushService(
    firebaseReady: ref.watch(firebaseReadyProvider),
    devices: ref.watch(deviceRepositoryProvider),
    mockBackend: useMockApi,
  );
  ref.onDispose(service.dispose);
  return service;
});
