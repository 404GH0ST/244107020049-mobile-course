import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/main.dart';
import 'package:week3_todo/providers/stats_provider.dart';
import 'package:week3_todo/router/app_router.dart';

void main() {
  setUp(() {
    StatsNotifier.forceErrorMode = false;
    appRouter.go('/');
  });

  tearDown(() {
    StatsNotifier.forceErrorMode = null;
  });

  testWidgets('menambah tugas baru', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: Week3App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Tugas (ToDo)'), findsOneWidget);

    // Tap tombol FAB untuk menambah tugas baru
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Tugas Baru'), findsOneWidget);

    // Ketik judul tugas baru
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, 'Kerjakan PR minggu 3');
    await tester.pump();

    // Tap tombol Tambah
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Verifikasi tugas baru muncul di dalam daftar
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}
