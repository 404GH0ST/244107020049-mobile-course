import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  // Fetch daftar ini hanya CRUD satu baris, tidak perlu wrapper use case.
  final result = await ref
      .watch(announcementRepositoryProvider)
      .fetchAnnouncements();
  if (result.failure != null) throw result.failure!;
  return result.value ?? const [];
}, retry: (_, _) => null);
final announcementProvider = FutureProvider.family<Announcement, String>((
  ref,
  id,
) async {
  final result = await ref.watch(getAnnouncementProvider).call(id);
  if (result.failure != null) throw result.failure!;
  final item = result.value;
  if (item == null) {
    throw const LocalFailure('Pengumuman tidak tersedia. Silakan coba lagi.');
  }
  return item;
}, retry: (_, _) => null);
