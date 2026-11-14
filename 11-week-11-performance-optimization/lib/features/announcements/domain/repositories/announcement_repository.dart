import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract interface class AnnouncementRepository {
  Future<Result<AnnouncementPage>> fetchAnnouncements({
    required int page,
    int pageSize = 20,
  });
  Future<Result<Announcement>> getAnnouncement(String id);
}
