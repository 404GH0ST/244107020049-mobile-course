import '../../../../core/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/ai_chat_repository.dart';

class SendChatMessage {
  const SendChatMessage(this._repository);

  final AiChatRepository _repository;

  static final RegExp _nikRegex = RegExp(r'\b\d{16}\b');
  static final RegExp _phoneRegex = RegExp(
    r'(?<!\w)(?:\+?62|0)[\s-]?8(?:[\s-]?\d){8,12}(?!\w)',
  );

  static String sanitizeInput(String text) {
    var sanitized = text;
    sanitized = sanitized.replaceAllMapped(
      _nikRegex,
      (match) => '[NIK_TERLINDUNGI]',
    );
    sanitized = sanitized.replaceAllMapped(
      _phoneRegex,
      (match) => '[NO_HP_TERLINDUNGI]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'),
      '[EMAIL_TERLINDUNGI]',
    );
    return sanitized;
  }

  static String? validate(String text) {
    if (text.trim().isEmpty) return 'Pertanyaan tidak boleh kosong.';
    if (text.trim().length > 500) return 'Pertanyaan maksimal 500 karakter.';
    if (RegExp(
      r'\b(alamat|jalan|jl|password|sandi|rekening)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return 'Hapus alamat, identitas, atau kredensial pribadi sebelum mengirim.';
    }
    return null;
  }

  Stream<String> stream(String question) {
    final error = validate(question);
    if (error != null) return Stream.error(ValidationFailure(error));
    return _repository.streamResponse(question: sanitizeInput(question.trim()));
  }

  Future<Result<String>> call({
    required String question,
    List<ChatMessage>? history,
  }) async {
    final trimmed = question.trim();
    final error = validate(trimmed);
    if (error != null) return (value: null, failure: ValidationFailure(error));
    final sanitizedQuestion = sanitizeInput(trimmed);
    return _repository.ask(question: sanitizedQuestion, history: null);
  }
}
