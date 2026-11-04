import '../../../../core/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/ai_chat_repository.dart';

class SendChatMessage {
  const SendChatMessage(this._repository);

  final AiChatRepository _repository;

  static final RegExp _nikRegex = RegExp(r'\b\d{16}\b');
  static final RegExp _phoneRegex = RegExp(r'\b(\+?62|08)\d{8,11}\b');

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
    return sanitized;
  }

  Future<Result<String>> call({
    required String question,
    List<ChatMessage>? history,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return (
        value: null,
        failure: const ValidationFailure('Pertanyaan tidak boleh kosong.'),
      );
    }

    if (trimmed.length > 500) {
      return (
        value: null,
        failure: const ValidationFailure('Pertanyaan maksimal 500 karakter.'),
      );
    }

    final sanitizedQuestion = sanitizeInput(trimmed);
    return _repository.ask(question: sanitizedQuestion, history: history);
  }
}
