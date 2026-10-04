import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_service.dart';
import 'auth_provider.dart';

final firebaseReadyProvider = Provider<bool>((ref) => false);
final pushServiceProvider = Provider((ref) {
  final service = PushService(
    firebaseReady: ref.watch(firebaseReadyProvider),
    dio: ref.watch(apiClientProvider),
    mockBackend: useMockApi,
  );
  ref.onDispose(service.dispose);
  return service;
});
