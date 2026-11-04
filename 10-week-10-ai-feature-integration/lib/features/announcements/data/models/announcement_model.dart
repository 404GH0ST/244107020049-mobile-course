import '../../domain/entities/announcement.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
  });
  final String id, title, subtitle, body;
  factory AnnouncementModel.fromJson(Map<String, Object?> json) =>
      AnnouncementModel(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        body: json['body'] as String,
      );
  Announcement toEntity() =>
      Announcement(id: id, title: title, subtitle: subtitle, body: body);
}
