import 'package:campus_notify/app/providers.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

ProviderContainer containerWith(FakeFeedRepository repo) =>
    ProviderContainer.test(
      overrides: [announcementRepositoryProvider.overrideWithValue(repo)],
    );

void main() {
  group('AnnouncementFeedNotifier dengan fake repository', () {
    test('meneruskan data dari repository apa adanya', () async {
      // Arrange
      final repo = FakeFeedRepository(
        items: [sampleAnnouncement(1), sampleAnnouncement(2)],
      );
      final container = containerWith(repo);
      // Act
      final feed = await container.read(announcementFeedProvider.future);
      // Assert
      expect(feed.items.map((a) => a.title), ['Pengumuman 1', 'Pengumuman 2']);
      expect(feed.hasMore, isFalse);
      expect(repo.fetchCalls, 1);
    });

    test('data kosong menjadi feed kosong tanpa halaman lanjutan', () async {
      final container = containerWith(FakeFeedRepository());
      final feed = await container.read(announcementFeedProvider.future);
      expect(feed.items, isEmpty);
      expect(feed.hasMore, isFalse);
    });

    test('failure tidak diam-diam berubah menjadi list kosong', () async {
      const failure = NetworkFailure('Tidak terhubung ke jaringan.');
      final container = containerWith(FakeFeedRepository(error: failure));
      await expectLater(
        container.read(announcementFeedProvider.future),
        throwsA(same(failure)),
      );
      final state = container.read(announcementFeedProvider);
      expect(state.hasError, isTrue);
      expect(state.hasValue, isFalse);
    });

    test('failure saat loadMore menjaga item yang sudah tampil', () async {
      final repo = FakeFeedRepository(
        items: [for (var n = 1; n <= 25; n++) sampleAnnouncement(n)],
      );
      final container = containerWith(repo);
      await container.read(announcementFeedProvider.future);
      repo.error = const NetworkFailure('Koneksi terputus.');
      await container.read(announcementFeedProvider.notifier).loadMore();
      final feed = container.read(announcementFeedProvider).value!;
      expect(feed.items, hasLength(20));
      expect(feed.loadMoreError, 'Koneksi terputus.');
      expect(feed.hasMore, isTrue, reason: 'masih bisa dicoba lagi');
    });
  });
}
