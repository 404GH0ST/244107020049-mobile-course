import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/usecases/process_ocr.dart';
import '../../domain/usecases/process_stt.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../data/sources/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepositoryImpl(ref.watch(aiServiceProvider));
});

final sendChatMessageUseCaseProvider = Provider<SendChatMessage>((ref) {
  return SendChatMessage(ref.watch(aiChatRepositoryProvider));
});

final processOcrUseCaseProvider = Provider<ProcessOcr>((ref) {
  return ProcessOcr(ref.watch(aiChatRepositoryProvider));
});

final processSttUseCaseProvider = Provider<ProcessSpeechToText>((ref) {
  return ProcessSpeechToText(ref.watch(aiChatRepositoryProvider));
});

class ApiKeyStatusNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadKey();
    return null;
  }

  Future<void> _loadKey() async {
    final repo = ref.read(aiChatRepositoryProvider);
    state = await repo.getApiKey();
  }

  Future<void> setKey(String key) async {
    final repo = ref.read(aiChatRepositoryProvider);
    await repo.saveApiKey(key);
    state = key.trim();
  }

  Future<void> clearKey() async {
    final repo = ref.read(aiChatRepositoryProvider);
    await repo.deleteApiKey();
    state = null;
  }
}

final apiKeyStatusProvider = NotifierProvider<ApiKeyStatusNotifier, String?>(
  ApiKeyStatusNotifier.new,
);

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(
      messages: [
        ChatMessage(
          id: 'welcome',
          text: 'Halo! Saya Asisten AI Kampus Polinema. Silakan tanyakan informasi seputar jadwal, KRS, beasiswa, atau gunakan fitur OCR dan Voice.',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
    );

    final useCase = ref.read(sendChatMessageUseCaseProvider);
    final result = await useCase(question: trimmed, history: state.messages);

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
      return;
    }

    final answer = result.value ?? '';
    final isFallback =
        answer.contains('Offline') ||
        answer.contains('kampus offline') ||
        answer.contains('basis data');

    final assistantMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: answer,
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      isOfflineFallback: isFallback,
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<void> sendOcr(String description) async {
    final ocrUseCase = ref.read(processOcrUseCaseProvider);
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await ocrUseCase(description);
    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
      return;
    }

    final ocrText = result.value ?? '';
    final ocrMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: ocrText,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, ocrMessage],
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<void> sendVoice(String sampleAudioQuery) async {
    final sttUseCase = ref.read(processSttUseCaseProvider);
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await sttUseCase(sampleAudioQuery);
    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
      return;
    }

    final transcribedText = result.value ?? '';
    state = state.copyWith(isLoading: false);

    // Automatically send transcribed text to assistant
    await sendMessage(transcribedText);
  }

  void clearChat() {
    state = ChatState(
      messages: [
        ChatMessage(
          id: 'welcome_reset',
          text: 'Percakapan dibersihkan. Ada yang dapat Asisten Kampus bantu lagi?',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
      errorMessage: null,
    );
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
