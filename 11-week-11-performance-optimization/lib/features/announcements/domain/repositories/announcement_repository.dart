import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract interface class AnnouncementRepository {
  Future<Result<List<Announcement>>> fetchAnnouncements();
  Future<Result<Announcement>> getAnnouncement(String id);
}
