import 'package:campus_notify/features/ai_chat/presentation/pages/chat_screen.dart';
import 'package:campus_notify/features/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:campus_notify/features/ai_chat/data/sources/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_secure_storage.dart';

void main() {
  Widget buildTestableWidget({FakeSecureStorage? storage}) {
    final fakeStorage = storage ?? FakeSecureStorage();
    final fakeAiService = AiService(storage: fakeStorage);

    return ProviderScope(
      overrides: [aiServiceProvider.overrideWithValue(fakeAiService)],
      child: const MaterialApp(home: ChatScreen()),
    );
  }

  testWidgets('menampilkan pesan sambutan awal dan tombol aksi', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Asisten AI Kampus'), findsOneWidget);
    expect(find.textContaining('Asisten AI Kampus Polinema'), findsOneWidget);
    expect(find.text('Jadwal kuliah hari Senin?'), findsOneWidget);
    expect(find.byKey(const Key('chat_input_field')), findsOneWidget);
  });

  testWidgets(
    'mengetik pesan dan mengirim menambahkan bubble chat user dan asisten',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final inputField = find.byKey(const Key('chat_input_field'));
      await tester.enterText(inputField, 'Bagaimana cara izin sakit kuliah?');
      await tester.tap(find.byKey(const Key('chat_send_button')));

      await tester.pumpAndSettle();

      expect(find.text('Panduan lokal offline'), findsOneWidget);
      expect(
        find.textContaining('Pengajuan izin ketidakhadiran kuliah'),
        findsOneWidget,
      );
      expect(find.text('Panduan lokal offline'), findsOneWidget);
    },
  );

  testWidgets('menekan chip saran prompt otomatis mengirimkan pertanyaan', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final chip = find.text('Jadwal kuliah hari Senin?');
    expect(chip, findsOneWidget);
    await tester.tap(chip);

    await tester.pumpAndSettle();

    expect(
      find.textContaining('Jadwal perkuliahan dapat dilihat'),
      findsOneWidget,
    );
  });

  testWidgets('membuka dialog pengaturan API key dan menyimpannya', (
    tester,
  ) async {
    final storage = FakeSecureStorage();
    await tester.pumpWidget(buildTestableWidget(storage: storage));
    await tester.pumpAndSettle();

    final keyButton = find.byTooltip('Pengaturan Kunci API');
    await tester.tap(keyButton);
    await tester.pumpAndSettle();

    expect(find.text('Kunci API Gemini'), findsOneWidget);

    final keyInput = find.byKey(const Key('api_key_dialog_field'));
    await tester.enterText(keyInput, 'AIzaSyDemoKey123');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Kunci API Gemini tersimpan aman di SecureStorage.'),
      findsOneWidget,
    );
    expect(await storage.read(key: 'ai_api_key'), equals('AIzaSyDemoKey123'));
  });

  testWidgets('gambar menawarkan kamera dan galeri untuk OCR dan deskripsi', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('OCR Dokumen'));
    await tester.pumpAndSettle();
    expect(find.text('Ekstrak teks dari galeri'), findsOneWidget);
    expect(find.text('Ekstrak teks dari kamera'), findsOneWidget);
    expect(find.text('Deskripsikan dari galeri'), findsOneWidget);
    expect(find.text('Deskripsikan dari kamera'), findsOneWidget);
    expect(find.textContaining('NIM: 244107020049'), findsNothing);
  });

  testWidgets('menolak alamat pribadi sebelum ada pesan atau request', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat_input_field')),
      'Alamat: Jalan Contoh 3',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hapus alamat'), findsOneWidget);
    expect(find.text('Anda'), findsNothing);
  });

  testWidgets('tombol bersihkan obrolan mengosongkan percakapan', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('chat_input_field')),
      'Tes halo',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('Tes halo'), findsOneWidget);

    final clearButton = find.byTooltip('Bersihkan Obrolan');
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Tes halo'), findsNothing);
    expect(find.textContaining('Percakapan dibersihkan'), findsOneWidget);
  });
}
