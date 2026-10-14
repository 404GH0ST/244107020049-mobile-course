abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const announcementPattern = '/pengumuman/:id';
  static String announcement(String id) => '/pengumuman/$id';
}

String routeFromMessage(Map<String, dynamic> data) {
  final value = data['route'];
  if (value is! String || value.trim().isEmpty) return AppRoutes.home;
  final route = value.startsWith('/') ? value : '/$value';
  return RegExp(r'^/pengumuman/[a-zA-Z0-9_-]+$').hasMatch(route)
      ? route
      : AppRoutes.home;
}
