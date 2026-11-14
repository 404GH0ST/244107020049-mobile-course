import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';
import '../sources/announcement_source.dart';

/// Cache memori sesi:
/// - feed: network-first, jatuh ke halaman cache (stale) saat request gagal;
/// - detail: cache-first dari baris feed yang sudah dimuat, sehingga
///   list -> detail -> back tidak memicu request ulang.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._source);
  final AnnouncementDataSource _source;
  final Map<int, AnnouncementPage> _pages = {};
  final Map<String, Announcement> _byId = {};

  static const _failure = LocalFailure(
    'Gagal membaca pengumuman. Silakan coba lagi.',
  );

  @override
  Future<Result<AnnouncementPage>> fetchAnnouncements({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final rows = await _source.fetch(
        offset: page * pageSize,
        limit: pageSize,
      );
      final items = [
        for (final row in rows) AnnouncementModel.fromJson(row).toEntity(),
      ];
      final result = (items: items, hasMore: items.length == pageSize);
      _pages[page] = result;
      for (final item in items) {
        _byId[item.id] = item;
      }
      return (value: result, failure: null);
    } catch (_) {
      final stale = _pages[page];
      if (stale != null) return (value: stale, failure: null);
      return (value: null, failure: _failure);
    }
  }

  @override
  Future<Result<Announcement>> getAnnouncement(String id) async {
    final cached = _byId[id];
    if (cached != null) return (value: cached, failure: null);
    try {
      final item = AnnouncementModel.fromJson(await _source.get(id)).toEntity();
      _byId[id] = item;
      return (value: item, failure: null);
    } catch (_) {
      return (value: null, failure: _failure);
    }
  }
}
