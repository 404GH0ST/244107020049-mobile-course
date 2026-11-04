import '../../../../core/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../sources/ai_service.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  AiChatRepositoryImpl(this._aiService);

  final AiService _aiService;

  @override
  Future<Result<String>> ask({
    required String question,
    List<ChatMessage>? history,
  }) async {
    try {
      final answer = await _aiService.ask(question);
      return (value: answer, failure: null);
    } catch (e) {
      return (
        value: null,
        failure: NetworkFailure(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  @override
  Stream<String> streamResponse({
    required String question,
    List<ChatMessage>? history,
  }) {
    return _aiService.streamAsk(question);
  }

  @override
  Future<String?> getApiKey() => _aiService.getApiKey();

  @override
  Future<void> saveApiKey(String key) => _aiService.saveApiKey(key);

  @override
  Future<void> deleteApiKey() => _aiService.deleteApiKey();

  @override
  Future<Result<String>> recognizeText(
    String imagePathOrDescription, {
    bool describe = false,
  }) async {
    try {
      final result = await _aiService.recognizeText(
        imagePathOrDescription,
        describe: describe,
      );
      return (value: result, failure: null);
    } catch (e) {
      return (
        value: null,
        failure: LocalFailure(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  @override
  Future<Result<String>> speechToText(String audioPathOrDescription) async {
    try {
      final result = await _aiService.speechToText(audioPathOrDescription);
      return (value: result, failure: null);
    } catch (e) {
      return (
        value: null,
        failure: LocalFailure(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  @override
  String getOfflineFallbackAnswer(String question) {
    return _aiService.getOfflineFallbackAnswer(question);
  }
}
