import 'package:campus_notify/app/presentation/pages/home_page.dart';
import 'package:campus_notify/app/providers.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/data/sources/announcement_source.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Sumber yang bisa dibuat gagal untuk menguji fallback cache.
class FlakySource extends AnnouncementSource {
  FlakySource() : super(total: 45, latency: Duration.zero);
  bool offline = false;
  @override
  Future<List<Map<String, Object?>>> fetch({
    int offset = 0,
    int limit = 20,
  }) async {
    if (offline) throw const FormatException('socket closed');
    return super.fetch(offset: offset, limit: limit);
  }
}

ProviderContainer feedContainer(AnnouncementSource source) =>
    ProviderContainer.test(
      overrides: [announcementSourceProvider.overrideWithValue(source)],
    );

void main() {
  group('Repository: pagination dan cache', () {
    test(
      'halaman dipotong per 20 dan hasMore false di halaman akhir',
      () async {
        final repo = AnnouncementRepositoryImpl(FlakySource());
        final first = await repo.fetchAnnouncements(page: 0);
        final last = await repo.fetchAnnouncements(page: 2);
        expect(first.value!.items, hasLength(20));
        expect(first.value!.items.first.id, '1');
        expect(first.value!.hasMore, isTrue);
        expect(last.value!.items, hasLength(5));
        expect(last.value!.hasMore, isFalse);
      },
    );

    test(
      'detail yang sudah ada di feed dibaca dari cache tanpa request',
      () async {
        final source = FlakySource();
        final repo = AnnouncementRepositoryImpl(source);
        await repo.fetchAnnouncements(page: 0);
        final before = source.requests;
        final detail = await repo.getAnnouncement('3');
        expect(detail.value!.title, 'Jadwal kuliah berubah');
        expect(source.requests, before);
        await repo.getAnnouncement('44');
        expect(
          source.requests,
          before + 1,
          reason: 'id di luar cache tetap fetch',
        );
      },
    );

    test('request gagal memakai halaman cache (stale) tanpa failure', () async {
      final source = FlakySource();
      final repo = AnnouncementRepositoryImpl(source);
      await repo.fetchAnnouncements(page: 0);
      source.offline = true;
      final stale = await repo.fetchAnnouncements(page: 0);
      expect(stale.failure, isNull);
      expect(stale.value!.items, hasLength(20));
      final missing = await repo.fetchAnnouncements(page: 1);
      expect(missing.failure, isA<LocalFailure>());
      expect(missing.failure!.message, isNot(contains('socket')));
    });
  });

  group('AnnouncementFeedNotifier', () {
    test(
      'loadMore menambah halaman, menolak panggilan ganda, berhenti di akhir',
      () async {
        final source = FlakySource();
        final container = feedContainer(source);
        final sub = container.listen(announcementFeedProvider, (_, _) {});
        addTearDown(sub.close);
        await container.read(announcementFeedProvider.future);
        final notifier = container.read(announcementFeedProvider.notifier);

        await Future.wait([notifier.loadMore(), notifier.loadMore()]);
        var feed = container.read(announcementFeedProvider).value!;
        expect(feed.items, hasLength(40));
        expect(source.requests, 2, reason: 'loadMore ganda hanya satu request');

        await notifier.loadMore();
        feed = container.read(announcementFeedProvider).value!;
        expect(feed.items, hasLength(45));
        expect(feed.hasMore, isFalse);
        await notifier.loadMore();
        expect(source.requests, 3);
      },
    );

    test('loadMore gagal menyimpan pesan tanpa menghapus item', () async {
      final source = FlakySource();
      final container = feedContainer(source);
      final sub = container.listen(announcementFeedProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(announcementFeedProvider.future);
      source.offline = true;
      await container.read(announcementFeedProvider.notifier).loadMore();
      final feed = container.read(announcementFeedProvider).value!;
      expect(feed.items, hasLength(20));
      expect(
        feed.loadMoreError,
        'Gagal membaca pengumuman. Silakan coba lagi.',
      );
      expect(feed.loadingMore, isFalse);
    });
  });

  test('detail autoDispose: tidak ditahan setelah halaman ditutup', () async {
    final container = feedContainer(FlakySource());
    final sub = container.listen(announcementProvider('3'), (_, _) {});
    await container.read(announcementProvider('3').future);
    expect(container.exists(announcementProvider('3')), isTrue);
    sub.close();
    await container.pump();
    expect(container.exists(announcementProvider('3')), isFalse);
  });

  testWidgets('HomePage hanya membangun tile yang terlihat dan memuat '
      'halaman berikutnya saat scroll', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final source = AnnouncementSource(latency: Duration.zero);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementSourceProvider.overrideWithValue(source),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(source.requests, 1, reason: 'hanya halaman pertama dimuat');

    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40 && source.requests < 4; i++) {
      await tester.drag(list, const Offset(0, -1500));
      await tester.pumpAndSettle();
    }
    expect(source.requests, greaterThanOrEqualTo(4), reason: 'infinite scroll');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    final loaded = container.read(announcementFeedProvider).value!.items.length;
    final built = find.byType(AnnouncementTile).evaluate().length;
    expect(loaded, greaterThanOrEqualTo(60));
    expect(built, greaterThan(0));
    expect(built, lessThan(loaded ~/ 3), reason: 'lazy: hanya tile terlihat');
  });
}
