import 'dart:io';

import 'package:campus_notify/features/ai_chat/data/sources/ai_service.dart';
import 'package:campus_notify/features/ai_chat/presentation/pages/chat_screen.dart';
import 'package:campus_notify/features/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ai_chat_test.dart' show capture, waitChat;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Gemini live chat, OCR, image understanding, dan STT di Android',
    (tester) async {
      debugPrint('PREPARE_LIVE_FIXTURES');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      final service = AiService();
      final input = File(
        '/data/user/0/id.ac.polinema.campus_notify/files/week10_test_key',
      );
      if (await input.exists()) {
        await service.saveApiKey(await input.readAsString());
        await input.delete();
      }
      expect(
        await service.getApiKey(),
        isNotNull,
        reason:
            'Jalankan live test melalui tool/run_emulator_checks.py --live.',
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
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Bagaimana cara menyiapkan pengisian KRS?',
      );
      await tester.tap(find.byKey(const Key('chat_send_button')));
      for (var i = 0; i < 350; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (!container.read(chatNotifierProvider).isLoading) break;
      }
      for (
        var attempt = 0;
        attempt < 2 &&
            container
                .read(chatNotifierProvider)
                .messages
                .last
                .isOfflineFallback;
        attempt++
      ) {
        debugPrint(
          'LIVE_RETRY: layanan belum merespons, menguji aksi Coba lagi',
        );
        await container.read(chatNotifierProvider.notifier).retry();
        await waitChat(tester);
      }
      final state = container.read(chatNotifierProvider);
      expect(state.isLoading, false);
      expect(
        state.messages.last.isOfflineFallback,
        false,
        reason: state.messages.last.text,
      );
      expect(state.messages.last.text.trim(), isNotEmpty);
      debugPrint('LIVE_CHAT_OUTPUT:${state.messages.last.text}');
      await capture(tester, '14_live_gemini_chat');
      final notifier = container.read(chatNotifierProvider.notifier);
      const base = '/data/user/0/id.ac.polinema.campus_notify/files';
      final ocr = await notifier.processMedia('$base/week10_notice.png');
      expect(ocr?.toUpperCase(), contains('PENGUMUMAN'));
      expect(ocr?.toUpperCase(), contains('FLUTTER'));
      debugPrint('LIVE_OCR_OUTPUT:$ocr');
      await tester.pumpAndSettle();
      await capture(tester, '15_live_ocr');
      final description = await notifier.processMedia(
        '$base/week10_notice.png',
        describe: true,
      );
      expect(description, isNotNull);
      expect(description!.trim(), isNotEmpty);
      debugPrint('LIVE_IMAGE_OUTPUT:$description');
      await tester.pumpAndSettle();
      await capture(tester, '16_live_image_understanding');
      final transcript = await notifier.processMedia(
        '$base/week10_question.m4a',
        audio: true,
      );
      expect(transcript?.toUpperCase(), contains('KRS'));
      expect(transcript?.toLowerCase(), isNot(contains('portal akademik')));
      debugPrint('LIVE_STT_OUTPUT:$transcript');
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        transcript!,
      );
      await tester.pumpAndSettle();
      await capture(tester, '17_live_stt_draft');
      for (final name in ['week10_notice.png', 'week10_question.m4a']) {
        await File('$base/$name').delete();
      }
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_AI'),
  );
}
