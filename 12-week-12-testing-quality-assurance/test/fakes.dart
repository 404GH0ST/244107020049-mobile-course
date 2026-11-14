import 'package:campus_notify/core/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<Result<AnnouncementPage>> fetchAnnouncements({
    required int page,
    int pageSize = 20,
  }) async {
    final item = await getAnnouncement('3');
    return (
      value: item.value == null ? null : (items: [item.value!], hasMore: false),
      failure: failure,
    );
  }
}

/// Fake feed untuk skenario sukses, kosong, dan gagal tanpa sumber data asli.
/// [error] membuat setiap request mengembalikan failure.
class FakeFeedRepository implements AnnouncementRepository {
  FakeFeedRepository({List<Announcement>? items, this.error})
    : items = items ?? const [];
  final List<Announcement> items;
  Failure? error;
  int fetchCalls = 0;

  @override
  Future<Result<AnnouncementPage>> fetchAnnouncements({
    required int page,
    int pageSize = 20,
  }) async {
    fetchCalls++;
    if (error != null) return (value: null, failure: error);
    final start = (page * pageSize).clamp(0, items.length);
    final end = (start + pageSize).clamp(0, items.length);
    return (
      value: (items: items.sublist(start, end), hasMore: end < items.length),
      failure: null,
    );
  }

  @override
  Future<Result<Announcement>> getAnnouncement(String id) async {
    if (error != null) return (value: null, failure: error);
    final item = items.where((a) => a.id == id).firstOrNull;
    return item == null
        ? (value: null, failure: const LocalFailure('Tidak ditemukan.'))
        : (value: item, failure: null);
  }
}

Announcement sampleAnnouncement(int n) => Announcement(
  id: '$n',
  title: 'Pengumuman $n',
  subtitle: 'Akademik • #$n',
  body: 'Isi pengumuman $n',
);

/// Ukuran layar Pixel (1080×2400 @2.6) agar tata letak sama dengan emulator.
void usePhoneScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
}
