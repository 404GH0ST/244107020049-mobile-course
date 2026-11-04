import 'dart:convert';

import 'package:campus_notify/features/ai_chat/data/sources/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_secure_storage.dart';

void main() {
  group('AiService unit tests', () {
    test('menggunakan offline fallback saat API key belum diatur', () async {
      final fakeStorage = FakeSecureStorage();
      final aiService = AiService(storage: fakeStorage);

      final answer = await aiService.ask('Bagaimana cara pengisian KRS?');
      expect(answer, contains('Pengisian dan revisi KRS'));
    });

    test(
      'mengirim prompt ke Gemini API saat API key tersedia dan response 200',
      () async {
        final fakeStorage = FakeSecureStorage({
          'ai_api_key': 'test_api_key_123',
        });
        final mockClient = MockClient((request) async {
          expect(
            request.url.queryParameters['key'],
            equals('test_api_key_123'),
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['contents'], isNotEmpty);

          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Jadwal kuliah dimulai pukul 07.30 WIB di GKB.'},
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final aiService = AiService(
          storage: fakeStorage,
          httpClient: mockClient,
        );

        final answer = await aiService.ask('Jadwal kuliah Senin?');
        expect(answer, equals('Jadwal kuliah dimulai pukul 07.30 WIB di GKB.'));
      },
    );

    test('menangani kuota 429 dengan beralih ke fallback offline', () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'test_key'});
      final mockClient = MockClient((_) async {
        return http.Response('Quota exceeded', 429);
      });

      final aiService = AiService(storage: fakeStorage, httpClient: mockClient);

      final answer = await aiService.ask('Info bayar UKT?');
      expect(answer, contains('Pembayaran UKT'));
      expect(answer, contains('basis data kampus offline'));
    });

    test('melemparkan exception jika API key invalid 401', () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'invalid_key'});
      final mockClient = MockClient((_) async {
        return http.Response('Unauthorized', 401);
      });

      final aiService = AiService(storage: fakeStorage, httpClient: mockClient);

      expect(() => aiService.ask('Halo'), throwsA(isA<Exception>()));
    });

    test('fallback ke pengetahuan lokal jika jaringan gagal', () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'test_key'});
      final mockClient = MockClient((_) async {
        throw http.ClientException('Network connection failed');
      });

      final aiService = AiService(storage: fakeStorage, httpClient: mockClient);

      final answer = await aiService.ask('Lokasi Gedung Kuliah Bersama?');
      expect(answer, contains('Gedung Kuliah Bersama (GKB)'));
      expect(answer, contains('Mode Offline'));
    });

    test('streamAsk memancarkan chunk teks bertahap', () async {
      final fakeStorage = FakeSecureStorage();
      final aiService = AiService(storage: fakeStorage);

      final stream = aiService.streamAsk('beasiswa');
      final chunks = await stream.toList();

      expect(chunks, isNotEmpty);
      expect(chunks.last, contains('beasiswa'));
    });

    test('recognizeText OCR mengekstrak informasi KTM', () async {
      final aiService = AiService(storage: FakeSecureStorage());
      final result = await aiService.recognizeText('ktm mahasiswa');

      expect(result, contains('NIM: 244107020049'));
      expect(result, contains('Agus Prasetyo'));
    });

    test('speechToText menerjemahkan suara ke teks', () async {
      final aiService = AiService(storage: FakeSecureStorage());
      final result = await aiService.speechToText('jadwal krs');

      expect(result, contains('Kapan jadwal pengisian KRS'));
    });

    test(
      'saveApiKey dan deleteApiKey mengelola storage dengan benar',
      () async {
        final fakeStorage = FakeSecureStorage();
        final aiService = AiService(storage: fakeStorage);

        expect(await aiService.getApiKey(), isNull);
        await aiService.saveApiKey('my_secret_key');
        expect(await aiService.getApiKey(), equals('my_secret_key'));
        await aiService.deleteApiKey();
        expect(await aiService.getApiKey(), isNull);
      },
    );
  });
}
