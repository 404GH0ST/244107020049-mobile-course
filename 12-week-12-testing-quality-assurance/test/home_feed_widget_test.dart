import 'dart:async';

import 'package:campus_notify/app/presentation/pages/home_page.dart';
import 'package:campus_notify/app/providers.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Feed yang menahan respons pertama sampai [gate] selesai.
class SlowFeedRepository extends FakeFeedRepository {
  SlowFeedRepository({super.items});
  final gate = Completer<void>();
  @override
  Future<Result<AnnouncementPage>> fetchAnnouncements({
    required int page,
    int pageSize = 20,
  }) async {
    await gate.future;
    return super.fetchAnnouncements(page: page, pageSize: pageSize);
  }
}

Future<void> pumpHome(WidgetTester tester, FakeFeedRepository repo) {
  usePhoneScreen(tester);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        announcementRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: const MaterialApp(home: HomePage()),
    ),
  );
}

/// Feed berada di bawah kartu status; geser sampai [finder] terlihat.
Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('loading tampil sebelum data, lalu diganti daftar', (
    tester,
  ) async {
    final repo = SlowFeedRepository(items: [sampleAnnouncement(1)]);
    await pumpHome(tester, repo);
    await tester.pump();
    await scrollTo(tester, find.byType(CircularProgressIndicator));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AnnouncementTile), findsNothing);

    repo.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await scrollTo(tester, find.byKey(const ValueKey('announcement-tile-1')));
    expect(find.text('Pengumuman 1'), findsOneWidget);
    expect(find.text('Semua pengumuman sudah dimuat.'), findsOneWidget);
  });

  testWidgets('feed kosong menampilkan empty state', (tester) async {
    await pumpHome(tester, FakeFeedRepository());
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Belum ada pengumuman.'));
    expect(find.byType(AnnouncementTile), findsNothing);
  });

  testWidgets('feed gagal menampilkan pesan dan Coba lagi memulihkan', (
    tester,
  ) async {
    final repo = FakeFeedRepository(
      items: [sampleAnnouncement(7)],
      error: const NetworkFailure('Tidak terhubung ke jaringan.'),
    );
    await pumpHome(tester, repo);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Coba lagi'));
    expect(find.text('Tidak terhubung ke jaringan.'), findsOneWidget);
    expect(find.text('Belum ada pengumuman.'), findsNothing);

    repo.error = null;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('announcement-tile-7')));
    expect(find.text('Pengumuman 7'), findsOneWidget);
    expect(repo.fetchCalls, 2);
  });
}
