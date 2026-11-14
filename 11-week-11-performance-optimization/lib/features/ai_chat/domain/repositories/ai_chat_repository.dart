import '../../../../core/failures.dart';
import '../entities/chat_message.dart';

abstract interface class AiChatRepository {
  Future<Result<String>> ask({
    required String question,
    List<ChatMessage>? history,
  });

  Stream<String> streamResponse({
    required String question,
    List<ChatMessage>? history,
  });

  Future<String?> getApiKey();
  Future<void> saveApiKey(String key);
  Future<void> deleteApiKey();

  Future<Result<String>> recognizeText(
    String imagePathOrDescription, {
    bool describe = false,
  });
  Future<Result<String>> speechToText(String audioPathOrDescription);
  String getOfflineFallbackAnswer(String question);
}
