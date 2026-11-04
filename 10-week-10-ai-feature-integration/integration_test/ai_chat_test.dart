import 'dart:async';
import 'dart:convert';

import 'package:campus_notify/app/campus_app.dart';
import 'package:campus_notify/features/ai_chat/data/sources/ai_service.dart';
import 'package:campus_notify/features/ai_chat/presentation/pages/chat_screen.dart';
import 'package:campus_notify/features/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fake_secure_storage.dart';

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump();
  debugPrint('SCREENSHOT:$name');
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
}

String event(String text) =>
    'data: ${jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    })}\n\n';

Future<void> waitChat(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChatScreen)),
  );
  for (var i = 0; i < 350; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!container.read(chatNotifierProvider).isLoading) break;
  }
  expect(container.read(chatNotifierProvider).isLoading, false);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'alur aplikasi, fallback, kunci, privasi, gambar, rekaman, dan Back',
    (tester) async {
      final service = AiService(storage: FakeSecureStorage());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiServiceProvider.overrideWithValue(service)],
          child: const CampusApp(),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Masuk').evaluate().isNotEmpty ||
            find.byTooltip('Tanya Asisten AI').evaluate().isNotEmpty) {
          break;
        }
      }
      if (find.text('Masuk').evaluate().isNotEmpty) {
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'demo@kampus.test',
        );
        await tester.enterText(find.byType(TextFormField).at(1), '123456');
        await tester.tap(find.text('Masuk'));
        await tester.pumpAndSettle();
      }
      for (
        var i = 0;
        i < 100 && find.byTooltip('Tanya Asisten AI').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byTooltip('Tanya Asisten AI'), findsOneWidget);
      await capture(tester, '01_home');
      await tester.tap(find.byTooltip('Tanya Asisten AI'));
      await tester.pumpAndSettle();
      expect(find.text('Asisten AI Kampus'), findsOneWidget);
      await capture(tester, '02_chat_offline');
      await tester.tap(find.text('Jadwal kuliah hari Senin?'));
      await tester.pumpAndSettle();
      expect(find.text('Panduan lokal offline'), findsOneWidget);
      await capture(tester, '03_offline_answer');
      await tester.tap(find.byTooltip('Pengaturan Kunci API'));
      await tester.pumpAndSettle();
      await capture(tester, '04_api_settings');
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bersihkan Obrolan'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Alamat: Jalan Contoh 3',
      );
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hapus alamat'), findsOneWidget);
      await capture(tester, '05_privacy_validation');
      await tester.enterText(find.byKey(const Key('chat_input_field')), '');
      await tester.tap(find.byTooltip('Bersihkan Obrolan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('OCR Dokumen'));
      await tester.pumpAndSettle();
      await capture(tester, '06_image_sources');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Speech-to-Text'));
      await tester.pumpAndSettle();
      await capture(tester, '07_voice_ready');
      await tester.tap(find.text('Mulai merekam'));
      await tester.pumpAndSettle();
      expect(find.text('Selesai merekam'), findsOneWidget);
      await capture(tester, '08_recording');
      await tester.tap(find.text('Selesai merekam'));
      await tester.pumpAndSettle();
      expect(find.text('Tinjau sebelum kirim'), findsOneWidget);
      await capture(tester, '09_media_consent');
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Campus Notify'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stream, cache, kuota, dan retry dengan transport HTTP terkendali',
    (tester) async {
      final controller = StreamController<List<int>>();
      var calls = 0;
      var fail = false;
      final service = AiService(
        storage: FakeSecureStorage({'ai_api_key': 'integration-test-only'}),
        httpClient: MockClient.streaming((_, _) async {
          calls++;
          if (fail) {
            return http.StreamedResponse(
              Stream.value(utf8.encode('Quota exceeded')),
              429,
            );
          }
          return http.StreamedResponse(controller.stream, 200);
        }),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff1769aa),
              ),
              useMaterial3: true,
            ),
            home: const ChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Bagaimana pengisian KRS?',
      );
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await capture(tester, '10_loading_fixture');
      controller.add(utf8.encode(event('Periksa portal akademik.')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Periksa portal akademik.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await capture(tester, '11_streaming_fixture');
      controller.add(
        utf8.encode(event(' Konfirmasikan dengan dosen pembimbing.')),
      );
      await controller.close();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bagaimana pengisian KRS?').last);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.textContaining('Cache sesi:'), findsOneWidget);
      await capture(tester, '12_cache_fixture');
      fail = true;
      tester
              .widget<TextField>(find.byKey(const Key('chat_input_field')))
              .controller!
              .text =
          'Panduan UKT';
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pumpAndSettle();
      await waitChat(tester);
      await capture(tester, '13_quota_fallback_fixture');
      final state = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      ).read(chatNotifierProvider);
      debugPrint(
        'FIXTURE_STATE: calls=$calls loading=${state.isLoading} answer=${state.messages.last.text}',
      );
      expect(find.textContaining('Kuota penyedia AI tercapai'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      final before = calls;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      await waitChat(tester);
      expect(calls, before + 1);
      expect(tester.takeException(), isNull);
    },
  );
}
