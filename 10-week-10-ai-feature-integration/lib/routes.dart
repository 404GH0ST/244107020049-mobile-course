abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const announcementPattern = '/pengumuman/:id';
  static String announcement(String id) => '/pengumuman/$id';
}
