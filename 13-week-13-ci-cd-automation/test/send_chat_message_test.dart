import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai_chat/domain/entities/chat_message.dart';
import 'package:campus_notify/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:campus_notify/features/ai_chat/domain/usecases/send_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAiChatRepository implements AiChatRepository {
  String? lastQuestion;

  @override
  Future<Result<String>> ask({
    required String question,
    List<ChatMessage>? history,
  }) async {
    lastQuestion = question;
    return (value: 'Jawaban untuk: $question', failure: null);
  }

  @override
  Stream<String> streamResponse({
    required String question,
    List<ChatMessage>? history,
  }) async* {
    lastQuestion = question;
    yield 'Jawaban streaming';
  }

  @override
  Future<String?> getApiKey() async => null;

  @override
  Future<void> saveApiKey(String key) async {}

  @override
  Future<void> deleteApiKey() async {}

  @override
  Future<Result<String>> recognizeText(
    String imagePathOrDescription, {
    bool describe = false,
  }) async => (value: 'OCR', failure: null);

  @override
  Future<Result<String>> speechToText(String audioPathOrDescription) async =>
      (value: 'STT', failure: null);

  @override
  String getOfflineFallbackAnswer(String question) => 'Fallback';
}

void main() {
  group('SendChatMessage UseCase tests', () {
    late FakeAiChatRepository repository;
    late SendChatMessage useCase;

    setUp(() {
      repository = FakeAiChatRepository();
      useCase = SendChatMessage(repository);
    });

    test('menolak pertanyaan kosong atau whitespace', () async {
      final result = await useCase(question: '   ');
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, contains('tidak boleh kosong'));
      expect(repository.lastQuestion, isNull);
    });

    test('menolak pertanyaan melebihi batas 500 karakter', () async {
      final longQuery = 'A' * 501;
      final result = await useCase(question: longQuery);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, contains('maksimal 500 karakter'));
      expect(repository.lastQuestion, isNull);
    });

    test('melakukan sanitasi NIK 16 digit demi perlindungan privasi', () async {
      const input =
          'Tolong cek data beasiswa untuk NIK 3507123456789012 milik saya';
      final result = await useCase(question: input);

      expect(result.failure, isNull);
      expect(repository.lastQuestion, contains('[NIK_TERLINDUNGI]'));
      expect(repository.lastQuestion, isNot(contains('3507123456789012')));
    });

    test('melakukan sanitasi nomor HP demi perlindungan privasi', () async {
      const input = 'Hubungi saya di 081234567890 atau +6281987654321 ya';
      final result = await useCase(question: input);

      expect(result.failure, isNull);
      expect(repository.lastQuestion, contains('[NO_HP_TERLINDUNGI]'));
      expect(repository.lastQuestion, isNot(contains('081234567890')));
      expect(repository.lastQuestion, isNot(contains('+6281987654321')));
    });

    test(
      'jalur stream meredaksi nomor berformat dan email sebelum jaringan',
      () async {
        await useCase
            .stream('Hubungi +62 812-3456-7890 atau demo@example.test')
            .toList();
        expect(
          repository.lastQuestion,
          'Hubungi [NO_HP_TERLINDUNGI] atau [EMAIL_TERLINDUNGI]',
        );
      },
    );

    test('menolak alamat dan sandi tanpa pola titik dua', () async {
      for (final text in [
        'alamat saya di sini',
        'password saya rahasia',
        'jalan Mawar nomor 1',
      ]) {
        final result = await useCase(question: text);
        expect(result.failure, isA<ValidationFailure>());
      }
      expect(repository.lastQuestion, isNull);
    });

    test(
      'stream menolak input kosong dan terlalu panjang tanpa request',
      () async {
        await expectLater(
          useCase.stream('  ').toList(),
          throwsA(isA<ValidationFailure>()),
        );
        await expectLater(
          useCase.stream('x' * 501).toList(),
          throwsA(isA<ValidationFailure>()),
        );
        expect(repository.lastQuestion, isNull);
      },
    );

    test('meneruskan pertanyaan valid ke repository', () async {
      const query = 'Kapan batas pembayaran UKT?';
      final result = await useCase(question: query);

      expect(result.failure, isNull);
      expect(result.value, contains(query));
      expect(repository.lastQuestion, equals(query));
    });
  });
}
