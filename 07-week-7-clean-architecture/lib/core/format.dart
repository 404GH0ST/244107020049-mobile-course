import '../routes.dart';

String formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
bool isAnnouncementId(String id) => RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
String routeFromMessage(Map<String, dynamic> data) {
  final value = data['route'];
  if (value is! String || value.trim().isEmpty) return AppRoutes.home;
  final route = value.startsWith('/') ? value : '/$value';
  return RegExp(r'^/pengumuman/[a-zA-Z0-9_-]+$').hasMatch(route)
      ? route
      : AppRoutes.home;
}
