import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ai_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_chat_message.dart';
export '../../../../app/ai_providers.dart';

class ApiKeyStatusNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      (await ref.read(aiChatRepositoryProvider).getApiKey())?.isNotEmpty ??
      false;

  Future<void> setKey(String key) async {
    await ref.read(aiChatRepositoryProvider).saveApiKey(key);
    if (ref.mounted) state = const AsyncData(true);
  }

  Future<void> clearKey() async {
    await ref.read(aiChatRepositoryProvider).deleteApiKey();
    if (ref.mounted) state = const AsyncData(false);
  }
}

final apiKeyStatusProvider = AsyncNotifierProvider<ApiKeyStatusNotifier, bool>(
  ApiKeyStatusNotifier.new,
);

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.canRetry = false,
  });
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool canRetry;
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool canRetry = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    canRetry: canRetry,
  );
}

class ChatNotifier extends Notifier<ChatState> {
  int _generation = 0;
  String? _lastQuestion;
  @override
  ChatState build() => ChatState(
    messages: [
      ChatMessage(
        id: 'welcome',
        text: 'Halo! Saya Asisten AI Kampus Polinema. Tanyakan panduan umum atau gunakan gambar dan suara. Jangan kirim data pribadi. Jawaban AI perlu diperiksa pada kanal resmi kampus.',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
      ),
    ],
  );

  Future<void> sendMessage(String text) async {
    if (state.isLoading) return;
    final validation = SendChatMessage.validate(text);
    if (validation != null) {
      state = state.copyWith(errorMessage: validation);
      return;
    }
    _lastQuestion = text;
    final generation = ++_generation;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final messages = [
      ...state.messages,
      ChatMessage(
        id: '$id-user',
        text: SendChatMessage.sanitizeInput(text.trim()),
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    ];
    state = state.copyWith(messages: messages, isLoading: true);
    try {
      await for (final answer
          in ref.read(sendChatMessageUseCaseProvider).stream(text)) {
        if (!ref.mounted || generation != _generation) return;
        final fallback = answer.contains('Mode Offline:');
        state = state.copyWith(
          isLoading: true,
          canRetry: fallback && ref.read(apiKeyStatusProvider).value == true,
          messages: [
            ...messages,
            ChatMessage(
              id: '$id-answer',
              text: SendChatMessage.sanitizeInput(answer),
              sender: MessageSender.assistant,
              timestamp: DateTime.now(),
              isOfflineFallback: fallback,
            ),
          ],
          errorMessage: fallback && ref.read(apiKeyStatusProvider).value == true
              ? 'Service AI tidak tersedia. Panduan offline ditampilkan. Coba lagi jika koneksi atau pengaturan sudah diperbaiki.'
              : null,
        );
      }
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          errorMessage: 'Jawaban gagal dimuat. Coba lagi.',
          canRetry: true,
        );
      }
    } finally {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: state.errorMessage,
          canRetry: state.canRetry,
        );
      }
    }
  }

  Future<void> handleErrorAction(bool retryable) async {
    if (retryable) {
      await retry();
    } else {
      state = state.copyWith();
    }
  }

  Future<void> retry() async {
    if (_lastQuestion != null) await sendMessage(_lastQuestion!);
  }

  Future<String?> processMedia(
    String path, {
    bool audio = false,
    bool describe = false,
  }) async {
    if (state.isLoading) return null;
    final generation = ++_generation;
    state = state.copyWith(isLoading: true);
    final repository = ref.read(aiChatRepositoryProvider);
    final result = audio
        ? await repository.speechToText(path)
        : await repository.recognizeText(path, describe: describe);
    if (!ref.mounted || generation != _generation) return null;
    final text = result.value == null
        ? null
        : SendChatMessage.sanitizeInput(result.value!);
    state = state.copyWith(
      isLoading: false,
      errorMessage: result.failure == null ? null : 'Media tidak dapat diproses. Periksa kunci API, koneksi, dan format berkas. Coba lagi tanpa data pribadi.',
      messages: text == null || audio
          ? state.messages
          : [
              ...state.messages,
              ChatMessage(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                text: '${describe ? 'Deskripsi gambar' : 'Hasil OCR'}: $text',
                sender: MessageSender.assistant,
                timestamp: DateTime.now(),
              ),
            ],
    );
    return text;
  }

  void clearChat() {
    ++_generation;
    _lastQuestion = null;
    state = ChatState(
      messages: [
        ChatMessage(
          id: 'reset',
          text: 'Percakapan dibersihkan. Ada yang dapat Asisten Kampus bantu lagi?',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
