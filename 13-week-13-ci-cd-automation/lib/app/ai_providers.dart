import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/ai_chat/data/sources/ai_service.dart';
import '../features/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import '../features/ai_chat/domain/repositories/ai_chat_repository.dart';
import '../features/ai_chat/domain/usecases/send_chat_message.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService();
  ref.onDispose(service.dispose);
  return service;
});
final aiChatRepositoryProvider = Provider<AiChatRepository>(
  (ref) => AiChatRepositoryImpl(ref.watch(aiServiceProvider)),
);
final sendChatMessageUseCaseProvider = Provider(
  (ref) => SendChatMessage(ref.watch(aiChatRepositoryProvider)),
);
