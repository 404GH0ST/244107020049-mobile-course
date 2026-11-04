import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:campus_notify/features/ai_chat/data/sources/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_secure_storage.dart';

Map<String, dynamic> candidate(String text) => {
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': text},
        ],
      },
    },
  ],
};
String event(String text) => 'data: ${jsonEncode(candidate(text))}\n\n';

void main() {
  AiService service(
    http.Client client, {
    FakeSecureStorage? storage,
    Duration? timeout,
  }) => AiService(
    storage: storage ?? FakeSecureStorage({'ai_api_key': 'test-key'}),
    httpClient: client,
    timeout: timeout ?? const Duration(seconds: 1),
  );

  test('tanpa kunci tidak pernah menghubungi jaringan', () async {
    final ai = service(
      MockClient((_) async => throw StateError('No network expected')),
      storage: FakeSecureStorage(),
    );
    expect(
      await ai.ask('KRS'),
      contains('Mode Offline: Kunci API belum diatur'),
    );
  });

  test('stream SSE memancarkan hasil sebelum respons selesai dan menjaga header key', () async {
    final controller = StreamController<List<int>>();
    final ai = service(
      MockClient.streaming((request, body) async {
        expect(request.url.path, endsWith(':streamGenerateContent'));
        expect(request.url.queryParameters, {'alt': 'sse'});
        expect(request.headers['x-goog-api-key'], 'test-key');
        expect(request.url.toString(), isNot(contains('test-key')));
        final payload = jsonDecode(await body.bytesToString()) as Map;
        expect(
          payload['system_instruction']['parts'][0]['text'],
          AiService.systemInstruction,
        );
        expect(payload['generationConfig']['maxOutputTokens'], 512);
        return http.StreamedResponse(controller.stream, 200);
      }),
    );
    final first = Completer<String>();
    final values = <String>[];
    final subscription = ai.streamAsk('Halo').listen((value) {
      values.add(value);
      if (!first.isCompleted) first.complete(value);
    });
    controller.add(utf8.encode(event('Halo ')));
    expect(await first.future, 'Halo ');
    final done = subscription.asFuture<void>();
    controller.add(utf8.encode(event('mahasiswa.')));
    await controller.close();
    await done;
    expect(values, ['Halo ', 'Halo mahasiswa.']);
  });

  test(
    'parser mempertahankan UTF8 dan SSE yang terpecah antar chunk',
    () async {
      final bytes = utf8.encode(
        ': ping\n\n${event('Halo, café!')}data: [DONE]\n\n',
      );
      final ai = service(
        MockClient.streaming(
          (_, _) async => http.StreamedResponse(
            Stream.fromIterable(bytes.map((b) => [b])),
            200,
          ),
        ),
      );
      expect(await ai.ask('Halo'), 'Halo, café!');
    },
  );

  for (final status in [400, 401, 403, 404, 429, 500, 503]) {
    test(
      'HTTP $status menghasilkan fallback berlabel tanpa request ulang',
      () async {
        var calls = 0;
        final ai = service(
          MockClient((_) async {
            calls++;
            return http.Response('DO_NOT_EXPOSE_PROVIDER_BODY', status);
          }),
        );
        final answer = await ai.ask('KRS');
        expect(answer, contains('Mode Offline:'));
        expect(answer, isNot(contains('DO_NOT_EXPOSE_PROVIDER_BODY')));
        expect(calls, 1);
      },
    );
  }

  test('network error tidak membocorkan URL atau API key', () async {
    final ai = service(
      MockClient(
        (_) async => throw http.ClientException('secret URL test-key'),
      ),
    );
    final answer = await ai.ask('UKT');
    expect(answer, contains('Koneksi AI tidak tersedia'));
    expect(answer, isNot(contains('test-key')));
  });

  test('timeout menghasilkan fallback ramah', () async {
    final ai = service(
      MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );
    expect(await ai.ask('jadwal'), contains('batas waktu'));
  });

  for (final payload in [
    'data: invalid-json\n\n',
    'data: {}\n\n',
    'data: {"candidates":[]}\n\n',
  ]) {
    test('respons invalid atau kosong menghasilkan fallback', () async {
      final ai = service(MockClient((_) async => http.Response(payload, 200)));
      expect(await ai.ask('Halo'), contains('Mode Offline:'));
    });
  }

  test(
    'cache sesi mencegah request berulang dan kedaluwarsa setelah 10 menit',
    () async {
      var calls = 0;
      var time = DateTime(2026, 11, 4, 10);
      final ai = AiService(
        storage: FakeSecureStorage({'ai_api_key': 'test-key'}),
        now: () => time,
        httpClient: MockClient((_) async {
          calls++;
          return http.Response(event('Panduan umum.'), 200);
        }),
      );
      await ai.ask('KRS');
      expect(await ai.ask(' krs '), contains('Cache sesi'));
      expect(calls, 1);
      time = time.add(const Duration(minutes: 11));
      await ai.ask('KRS');
      expect(calls, 2);
    },
  );

  test(
    'batas harian disimpan dan tanggal berikutnya mengizinkan request',
    () async {
      final storage = FakeSecureStorage({
        'ai_api_key': 'test-key',
        'ai_usage': '2026-11-04|20',
      });
      var time = DateTime(2026, 11, 4);
      var calls = 0;
      final ai = AiService(
        storage: storage,
        now: () => time,
        httpClient: MockClient((_) async {
          calls++;
          return http.Response(event('Halo'), 200);
        }),
      );
      expect(await ai.ask('Halo'), contains('20 request'));
      expect(calls, 0);
      time = time.add(const Duration(days: 1));
      expect(await ai.ask('Halo'), 'Halo');
      expect(calls, 1);
    },
  );

  test(
    'OCR, deskripsi, dan STT mengirim byte aktual serta MIME yang sesuai',
    () async {
      final dir = await Directory.systemTemp.createTemp('week10-test');
      addTearDown(() => dir.delete(recursive: true));
      final image = await File('${dir.path}/notice.png')
          .writeAsBytes([137, 80, 78, 71]);
      final audio = await File('${dir.path}/voice.m4a')
          .writeAsBytes([0, 1, 2, 3]);
      final prompts = <String>[];
      final ai = service(
        MockClient((request) async {
          expect(request.url.path, endsWith(':generateContent'));
          final parts =
              jsonDecode(request.body)['contents'][0]['parts'] as List;
          prompts.add(parts[0]['text'] as String);
          final media = parts[1]['inline_data'] as Map;
          expect(base64Decode(media['data'] as String), isNotEmpty);
          expect(media['mime_type'], anyOf('image/png', 'audio/mp4'));
          return http.Response(
            jsonEncode(candidate('Hasil dari fixture API.')),
            200,
          );
        }),
      );
      expect(await ai.recognizeText(image.path), 'Hasil dari fixture API.');
      await ai.recognizeText(image.path, describe: true);
      await ai.speechToText(audio.path);
      expect(prompts[0], contains('Ekstrak teks'));
      expect(prompts[1], contains('Deskripsikan objek'));
      expect(prompts[2], contains('Transkripsikan'));
    },
  );

  test('media offline gagal jelas dan tidak mengarang hasil', () async {
    final file = await File('${Directory.systemTemp.path}/week10-empty.png')
        .writeAsBytes([1]);
    addTearDown(file.delete);
    final ai = service(
      MockClient((_) async => throw StateError('No network')),
      storage: FakeSecureStorage(),
    );
    await expectLater(ai.recognizeText(file.path), throwsA(isA<Exception>()));
  });

  test('berkas lebih dari 4 MB ditolak sebelum jaringan', () async {
    final file = await File('${Directory.systemTemp.path}/week10-large.png')
        .writeAsBytes(List.filled(4 * 1024 * 1024 + 1, 0));
    addTearDown(file.delete);
    final ai = service(MockClient((_) async => throw StateError('No network')));
    await expectLater(ai.recognizeText(file.path), throwsA(isA<Exception>()));
  });

  test('simpan dan hapus kunci secure storage', () async {
    final ai = service(
      MockClient((_) async => http.Response('', 500)),
      storage: FakeSecureStorage(),
    );
    await ai.saveApiKey(' test-key ');
    expect(await ai.getApiKey(), 'test-key');
    await ai.deleteApiKey();
    expect(await ai.getApiKey(), isNull);
  });
}
