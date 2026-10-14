import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/mock_campus_adapter.dart';
import '../data/token_store.dart';

final tokenStoreProvider = Provider((ref) => TokenStore());
final authRepositoryProvider = Provider((ref) => AuthRepository());
final mockCampusProvider = Provider((ref) => MockCampusAdapter());
const useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: true);
final apiClientProvider = Provider((ref) {
  final dio = buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
    onSessionExpired: () =>
        ref.read(authStateProvider.notifier).expireSession(),
  );
  if (useMockApi) dio.httpClientAdapter = ref.watch(mockCampusProvider);
  ref.onDispose(() => dio.close());
  return dio;
});
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final store = ref.watch(tokenStoreProvider);
    final access = await store.readAccess();
    final refresh = await store.readRefresh();
    return access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim(), password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
  }

  Future<void> expireSession() => logout();
}
