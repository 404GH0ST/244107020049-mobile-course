import '../../../../core/failures.dart';
import '../repositories/ai_chat_repository.dart';

class ProcessSpeechToText {
  const ProcessSpeechToText(this._repository);

  final AiChatRepository _repository;

  Future<Result<String>> call(String audioPathOrDescription) async {
    final trimmed = audioPathOrDescription.trim();
    if (trimmed.isEmpty) {
      return (
        value: null,
        failure: const ValidationFailure('Rekaman suara tidak ditemukan.'),
      );
    }
    return _repository.speechToText(trimmed);
  }
}
