import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcement.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('GetAnnouncement meneruskan entity dari repository palsu', () async {
    final repo = FakeAnnouncementRepository();
    final result = await GetAnnouncement(repo).call('3');
    expect(result.failure, isNull);
    expect(result.value?.id, '3');
    expect(result.value?.title, 'Jadwal kuliah berubah');
    expect(repo.calls, 1);
  });
  test('GetAnnouncement meneruskan failure tanpa exception', () async {
    const failure = LocalFailure('Gagal membaca pengumuman.');
    final result = await GetAnnouncement(
      FakeAnnouncementRepository(failure: failure),
    ).call('3');
    expect(result.failure, same(failure));
    expect(result.value, isNull);
  });
  test('ID tidak valid ditolak sebelum akses repository', () async {
    final repo = FakeAnnouncementRepository();
    final result = await GetAnnouncement(repo).call('../3');
    expect(result.failure, isA<ValidationFailure>());
    expect(repo.calls, 0);
  });
}
