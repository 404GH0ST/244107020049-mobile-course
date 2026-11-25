import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

class AnnouncementFeed {
  const AnnouncementFeed({
    this.items = const [],
    this.nextPage = 0,
    this.hasMore = true,
    this.loadingMore = false,
    this.loadMoreError,
  });
  final List<Announcement> items;
  final int nextPage;
  final bool hasMore;
  final bool loadingMore;
  final String? loadMoreError;
}

/// Feed berhalaman: halaman pertama dimuat di [build], halaman berikutnya
/// lewat [loadMore] saat scroll mendekati akhir list.
class AnnouncementFeedNotifier extends AsyncNotifier<AnnouncementFeed> {
  static const pageSize = 20;

  @override
  Future<AnnouncementFeed> build() async {
    final first = await _load(ref.watch(announcementRepositoryProvider), 0);
    return AnnouncementFeed(
      items: first.items,
      nextPage: 1,
      hasMore: first.hasMore,
    );
  }

  Future<AnnouncementPage> _load(AnnouncementRepository repo, int page) async {
    final result = await repo.fetchAnnouncements(
      page: page,
      pageSize: pageSize,
    );
    if (result.failure != null) throw result.failure!;
    return result.value!;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        state.isLoading ||
        !current.hasMore ||
        current.loadingMore) {
      return;
    }
    final loading = AnnouncementFeed(
      items: current.items,
      nextPage: current.nextPage,
      hasMore: current.hasMore,
      loadingMore: true,
    );
    state = AsyncData(loading);
    AnnouncementFeed next;
    try {
      final page = await _load(
        ref.read(announcementRepositoryProvider),
        current.nextPage,
      );
      next = AnnouncementFeed(
        items: [...current.items, ...page.items],
        nextPage: current.nextPage + 1,
        hasMore: page.hasMore,
      );
    } on Failure catch (failure) {
      next = AnnouncementFeed(
        items: current.items,
        nextPage: current.nextPage,
        hasMore: current.hasMore,
        loadMoreError: failure.message,
      );
    }
    // Abaikan hasil lama bila feed sudah di-refresh atau provider dibuang.
    if (ref.mounted && identical(state.value, loading)) {
      state = AsyncData(next);
    }
  }
}

final announcementFeedProvider =
    AsyncNotifierProvider<AnnouncementFeedNotifier, AnnouncementFeed>(
      AnnouncementFeedNotifier.new,
      retry: (_, _) => null,
    );

// autoDispose: detail yang sudah ditutup tidak ditahan selama sesi.
final announcementProvider = FutureProvider.autoDispose
    .family<Announcement, String>((ref, id) async {
      final result = await ref.watch(getAnnouncementProvider).call(id);
      if (result.failure != null) throw result.failure!;
      final item = result.value;
      if (item == null) {
        throw const LocalFailure(
          'Pengumuman tidak tersedia. Silakan coba lagi.',
        );
      }
      return item;
    }, retry: (_, _) => null);
