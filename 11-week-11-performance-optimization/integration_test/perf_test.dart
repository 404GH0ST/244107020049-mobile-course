import 'package:campus_notify/app/campus_app.dart';
import 'package:campus_notify/app/providers.dart';
import 'package:campus_notify/features/announcements/data/sources/announcement_source.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Skenario codelab Minggu 11: buka list, scroll cepat, buka detail,
// kembali, pull to refresh. Dijalankan dengan `flutter drive --profile`.
Future<void> marker(WidgetTester tester, String line) async {
  await tester.pump();
  debugPrint(line);
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> openAndReturn(WidgetTester tester, String id) async {
  final tile = find.textContaining('#$id').first;
  await tester.tap(tile);
  await tester.pumpAndSettle();
  await waitFor(tester, find.text('Tujuan deep link: /pengumuman/$id'));
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
  await waitFor(tester, find.text('Pengumuman'));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('profil skenario list, detail, back, refresh', (tester) async {
    final source = AnnouncementSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [announcementSourceProvider.overrideWithValue(source)],
        child: const CampusApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Masuk').evaluate().isNotEmpty ||
          find.text('Pengumuman').evaluate().isNotEmpty) {
        break;
      }
    }
    if (find.text('Masuk').evaluate().isNotEmpty) {
      // Login bukan bagian yang diprofil; masuk lewat notifier agar
      // keyboard sistem tidak mengganggu skenario.
      await ProviderScope.containerOf(tester.element(find.text('Masuk')))
          .read(authStateProvider.notifier)
          .login('demo@kampus.test', '123456');
      await tester.pumpAndSettle();
    }
    await waitFor(tester, find.text('Jadwal kuliah berubah'));
    final list = find.byType(Scrollable).first;
    final container = ProviderScope.containerOf(
      tester.element(find.text('Pengumuman')),
    );

    await marker(tester, 'MEMINFO:list_start');
    final requestsBefore = source.requests;
    await binding.traceAction(() async {
      for (var i = 0; i < 6; i++) {
        await tester.fling(list, const Offset(0, -1400), 5000);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 6; i++) {
        await tester.fling(list, const Offset(0, 1400), 5000);
        await tester.pumpAndSettle();
      }
      await openAndReturn(tester, '3');
      await tester.fling(list, const Offset(0, 600), 2000);
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, 500));
      await tester.pump();
      await tester.pumpAndSettle();
      await waitFor(tester, find.text('Jadwal kuliah berubah'));
    }, reportKey: 'scenario');
    await marker(tester, 'SCREENSHOT:profile');

    // Langkah 5: list -> detail -> back sebanyak 5 kali.
    for (final id in ['1', '2', '3', '4', '5']) {
      await openAndReturn(tester, id);
    }
    await marker(tester, 'MEMINFO:list_after_5_details');
    final retained = [
      for (final id in ['1', '2', '3', '4', '5'])
        if (container.exists(announcementProvider(id))) id,
    ];
    binding.reportData = {
      ...?binding.reportData,
      'stats': {
        'sourceRequests': source.requests - requestsBefore,
        'retainedDetailProviders': retained,
      },
    };
    debugPrint('STATS:${binding.reportData!['stats']}');
  });
}
