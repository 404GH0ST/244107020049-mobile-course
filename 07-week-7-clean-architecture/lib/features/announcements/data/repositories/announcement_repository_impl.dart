import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';
import '../sources/announcement_source.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl(this._source);
  final AnnouncementDataSource _source;
  @override
  Future<Result<List<Announcement>>> fetchAnnouncements() async {
    try {
      return (
        value: (await _source.fetch())
            .map((row) => AnnouncementModel.fromJson(row).toEntity())
            .toList(),
        failure: null,
      );
    } catch (_) {
      return (
        value: null,
        failure: const LocalFailure(
          'Gagal membaca pengumuman. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<Result<Announcement>> getAnnouncement(String id) async {
    try {
      return (
        value: AnnouncementModel.fromJson(await _source.get(id)).toEntity(),
        failure: null,
      );
    } catch (_) {
      return (
        value: null,
        failure: const LocalFailure(
          'Gagal membaca pengumuman. Silakan coba lagi.',
        ),
      );
    }
  }
}
