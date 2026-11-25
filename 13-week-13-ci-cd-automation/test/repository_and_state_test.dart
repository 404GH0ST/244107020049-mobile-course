import 'package:campus_notify/app/providers.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/data/models/announcement_model.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/data/sources/announcement_source.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcement_page.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class BrokenSource extends AnnouncementSource {
  @override
  Future<Map<String, Object?>> get(String id) async =>
      throw const FormatException('internal JSON secret');
}

void main() {
  test('Model memetakan data ke entity tanpa mapping di domain', () {
    final item = AnnouncementModel.fromJson({
      'id': '3',
      'title': 'Judul',
      'subtitle': 'Contoh',
      'body': 'Isi',
    }).toEntity();
    expect(item.id, '3');
    expect(item.title, 'Judul');
  });
  test(
    'Repository memetakan exception mentah menjadi failure ramah pengguna',
    () async {
      final result = await AnnouncementRepositoryImpl(BrokenSource())
          .getAnnouncement('3');
      expect(result.failure, isA<LocalFailure>());
      expect(result.value, isNull);
      expect(result.failure!.message, isNot(contains('internal JSON secret')));
    },
  );
  test(
    'DI auth bisa diganti fake; login logout dan demo tanpa plugin',
    () async {
      final fake = FakeAuthRepository();
      final container = ProviderContainer.test(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      expect(await container.read(authStateProvider.future), isFalse);
      await container
          .read(authStateProvider.notifier)
          .login('demo@kampus.test', '123456');
      expect(container.read(authStateProvider).value, isTrue);
      final demoSubscription = container.listen(sessionDemoProvider, (_, _) {});
      addTearDown(demoSubscription.close);
      await container.read(sessionDemoProvider.notifier).run(false);
      expect(
        container.read(sessionDemoProvider).message,
        contains('retry 200'),
      );
      demoSubscription.close();
      await container.pump();
      final freshDemo = container.listen(sessionDemoProvider, (_, _) {});
      addTearDown(freshDemo.close);
      expect(container.read(sessionDemoProvider).message, 'Belum diuji');
      await container.read(authStateProvider.notifier).logout();
      expect(container.read(authStateProvider).value, isFalse);
      expect(fake.saved, isNull);
    },
  );
  testWidgets('UI failure hanya menampilkan message dan retry memuat entity', (
    tester,
  ) async {
    final container = ProviderContainer.test(
      overrides: [
        announcementRepositoryProvider.overrideWithValue(
          FakeAnnouncementRepository(
            failure: const LocalFailure('Gagal membaca pengumuman.'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AnnouncementPage(id: '3')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gagal membaca pengumuman.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    container.updateOverrides([
      announcementRepositoryProvider.overrideWithValue(
        FakeAnnouncementRepository(),
      ),
    ]);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal kuliah berubah'), findsOneWidget);
    expect(container.read(announcementProvider('3')).hasValue, isTrue);
  });
}
