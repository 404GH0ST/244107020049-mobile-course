import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/session_expiry.dart';

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
  retry: (_, _) => null,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    ref.listen(sessionExpiryProvider, (_, _) => expireSession());
    final result = await ref.watch(authRepositoryProvider).restoreSession();
    if (result.failure != null) throw result.failure!;
    return result.value ?? false;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(loginProvider)
        .call(email: email, password: password);
    if (!ref.mounted) return;
    state = result.failure != null
        ? AsyncError(result.failure!, StackTrace.current)
        : AsyncData(result.value ?? false);
  }

  Future<void> logout() async {
    final result = await ref.read(authRepositoryProvider).logout();
    if (!ref.mounted) return;
    state = result.failure != null
        ? AsyncError(result.failure!, StackTrace.current)
        : const AsyncData(false);
  }

  // Interceptor sudah menghapus token sebelum callback ini.
  void expireSession() {
    state = const AsyncData(false);
  }
}

final sessionDemoProvider =
    NotifierProvider.autoDispose<SessionDemoNotifier, SessionDemoState>(
      SessionDemoNotifier.new,
    );

class SessionDemoState {
  const SessionDemoState({this.busy = false, this.message = 'Belum diuji'});
  final bool busy;
  final String message;
}

class SessionDemoNotifier extends Notifier<SessionDemoState> {
  @override
  SessionDemoState build() => const SessionDemoState();
  Future<void> run(bool failRefresh) async {
    if (state.busy) return;
    state = SessionDemoState(busy: true, message: state.message);
    final result = await ref
        .read(authRepositoryProvider)
        .demoRefresh(failRefresh: failRefresh);
    if (!ref.mounted) return;
    state = SessionDemoState(
      message: result.failure?.message ?? result.value ?? 'Sukses',
    );
  }
}
