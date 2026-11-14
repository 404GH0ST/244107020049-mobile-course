import 'dart:async';

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

Future<void> waitFeed(WidgetTester tester) async {
  await waitFor(tester, find.byTooltip('Keluar'));
  final container = ProviderScope.containerOf(
    tester.element(find.byTooltip('Keluar')),
  );
  for (var i = 0; i < 150; i++) {
    final feed = container.read(announcementFeedProvider);
    if (feed.hasValue && !feed.isLoading) break;
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Scroll nyata mengikuti vsync: 2000 px dalam 500 ms (±4000 px/s),
/// setiap frame animasi ikut terekam di timeline.
Future<void> scrollBy(WidgetTester tester, double delta) async {
  final position = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  final target = (position.pixels + delta).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  unawaited(
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openAndReturn(WidgetTester tester, String id) async {
  // Subtitle diakhiri '#<id>'; RegExp mencegah '#3' cocok dengan '#30'.
  final tile = find.textContaining(RegExp('#$id\$'));
  final list = find.byType(Scrollable).first;
  // Pada list lazy tile di atas viewport belum di-build: geser ke atas dulu,
  // lalu ke bawah sampai terlihat. Keduanya no-op bila tile sudah terlihat.
  for (var i = 0; i < 60 && tile.hitTestable().evaluate().isEmpty; i++) {
    if (tile.evaluate().isNotEmpty) break;
    if (find.text('Pengumuman').evaluate().isNotEmpty) break;
    await tester.drag(list, const Offset(0, 600));
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(tile, 300, scrollable: list);
  // Posisikan tile di tengah layar agar tap tidak mengenai FAB.
  unawaited(
    Scrollable.ensureVisible(tester.element(tile.first), alignment: 0.4),
  );
  await tester.pumpAndSettle();
  await tester.tap(tile.first);
  await tester.pumpAndSettle();
  await waitFor(tester, find.text('Tujuan deep link: /pengumuman/$id'));
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
  await waitFor(tester, find.byTooltip('Keluar'));
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
          find.byTooltip('Keluar').evaluate().isNotEmpty) {
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
    await waitFeed(tester);
    final list = find.byType(Scrollable).first;
    final container = ProviderScope.containerOf(
      tester.element(find.byTooltip('Keluar')),
    );

    await marker(tester, 'MEMINFO:list_start');
    final requestsBefore = source.requests;
    await binding.traceAction(() async {
      for (var i = 0; i < 8; i++) {
        await scrollBy(tester, 2000);
      }
      for (var i = 0; i < 8; i++) {
        await scrollBy(tester, -2000);
      }
      await openAndReturn(tester, '3');
      await scrollBy(tester, -100000);
      await tester.drag(list, const Offset(0, 500));
      await tester.pump();
      await tester.pumpAndSettle();
      await waitFeed(tester);
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
