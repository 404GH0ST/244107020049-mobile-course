import '../../../../core/failures.dart';
import '../repositories/ai_chat_repository.dart';

class ProcessOcr {
  const ProcessOcr(this._repository);

  final AiChatRepository _repository;

  Future<Result<String>> call(String imagePathOrDescription) async {
    final trimmed = imagePathOrDescription.trim();
    if (trimmed.isEmpty) {
      return (
        value: null,
        failure: const ValidationFailure('Sumber gambar OCR tidak valid.'),
      );
    }
    return _repository.recognizeText(trimmed);
  }
}
