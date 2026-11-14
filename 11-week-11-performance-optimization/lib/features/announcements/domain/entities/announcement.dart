class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
  });
  final String id;
  final String title;
  final String subtitle;
  final String body;
}

/// Satu halaman feed; [hasMore] false berarti tidak perlu request lanjutan.
typedef AnnouncementPage = ({List<Announcement> items, bool hasMore});
