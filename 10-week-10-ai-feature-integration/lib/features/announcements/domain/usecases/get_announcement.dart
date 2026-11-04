import '../../../../core/failures.dart';
import '../../../../core/format.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncement {
  const GetAnnouncement(this._repository);
  final AnnouncementRepository _repository;
  Future<Result<Announcement>> call(String id) async {
    if (!isAnnouncementId(id)) {
      return (
        value: null,
        failure: const ValidationFailure('ID pengumuman tidak valid.'),
      );
    }
    final result = await _repository.getAnnouncement(id);
    if (result.failure != null || result.value != null) return result;
    return (
      value: null,
      failure: const LocalFailure(
        'Pengumuman tidak tersedia. Silakan coba lagi.',
      ),
    );
  }
}
