import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginFailure, this.saveFailure});
  final Failure? loginFailure, saveFailure;
  String? email;
  AuthSession? saved;
  int loginCalls = 0, saveCalls = 0;
  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    this.email = email;
    return (
      value: loginFailure == null
          ? const AuthSession(access: 'access', refresh: 'refresh')
          : null,
      failure: loginFailure,
    );
  }

  @override
  Future<Result<void>> saveSession(AuthSession session) async {
    saveCalls++;
    if (saveFailure == null) saved = session;
    return (value: null, failure: saveFailure);
  }

  @override
  Future<Result<bool>> restoreSession() async =>
      (value: saved != null, failure: null);
  @override
  Future<Result<void>> logout() async {
    saved = null;
    return (value: null, failure: null);
  }

  @override
  Future<Result<String>> demoRefresh({required bool failRefresh}) async =>
      failRefresh
      ? (value: null, failure: const SessionFailure('Sesi berakhir.'))
      : (value: '401 → refresh sekali → retry 200', failure: null);
}

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.failure});
  final Failure? failure;
  int calls = 0;
  @override
  Future<Result<Announcement>> getAnnouncement(String id) async {
    calls++;
    return (
      value: failure == null
          ? Announcement(
              id: id,
              title: 'Jadwal kuliah berubah',
              subtitle: 'Contoh',
              body: 'Ruang A2',
            )
          : null,
      failure: failure,
    );
  }

  @override
  Future<Result<List<Announcement>>> fetchAnnouncements() async {
    final item = await getAnnouncement('3');
    return (value: item.value == null ? null : [item.value!], failure: failure);
  }
}
