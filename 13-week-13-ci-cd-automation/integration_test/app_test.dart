import 'package:campus_notify/main.dart' as app;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Alur utama Campus Notify di emulator: login (invalid lalu valid) ->
// feed pengumuman -> detail -> kembali -> logout.
// `tool/run_app_test.py` menangkap layar setiap baris SCREENSHOT:<nama>.

/// Tunggu kondisi asinkron (sesi, latensi feed) tanpa delay tetap.
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

/// Tutup keyboard dulu agar tombol tidak tertutup, lalu tekan.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Beri waktu skrip host mengambil screenshot dari emulator.
Future<void> screenshot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  debugPrint('SCREENSHOT:$name');
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login, buka pengumuman, kembali, lalu logout', (tester) async {
    app.main();
    final login = find.byKey(const Key('login-submit-button'));
    final logout = find.byTooltip('Keluar');
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (login.evaluate().isNotEmpty || logout.evaluate().isNotEmpty) break;
    }
    // Sesi dari run sebelumnya tersimpan di secure storage: mulai dari login.
    if (logout.evaluate().isNotEmpty) {
      await tester.tap(logout);
      await waitFor(tester, login);
    }

    // Input invalid ditolak di form.
    await tester.enterText(find.byKey(const Key('login-email-field')), 'demo@');
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      '123',
    );
    await tapVisible(tester, login);
    await tester.pumpAndSettle();
    expect(find.text('Masukkan email yang valid'), findsOneWidget);
    expect(find.text('Minimal 6 karakter'), findsOneWidget);
    await screenshot(tester, 'login_invalid');

    // Input valid masuk ke beranda.
    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'demo@kampus.test',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      '123456',
    );
    await tapVisible(tester, login);
    await waitFor(tester, logout);

    final tile = find.byKey(const ValueKey('announcement-tile-3'));
    await waitFor(tester, find.byType(Scrollable));
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // Letakkan tile di tengah layar agar tidak tertutup FAB.
    await Scrollable.ensureVisible(tester.element(tile), alignment: 0.4);
    await tester.pumpAndSettle();
    expect(find.text('Jadwal kuliah berubah'), findsWidgets);
    await screenshot(tester, 'home_feed');

    await tester.tap(tile);
    await waitFor(tester, find.textContaining('Ruang A2'));
    expect(find.text('Pengumuman #3'), findsOneWidget);
    await screenshot(tester, 'announcement_detail');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await waitFor(tester, tile);

    await tester.tap(logout);
    await waitFor(tester, login);
    expect(find.text('Pengumuman kampus'), findsOneWidget);
  });
}
