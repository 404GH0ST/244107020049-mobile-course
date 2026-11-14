enum MessageSender { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isOfflineFallback = false,
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isOfflineFallback;

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isOfflineFallback,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          sender == other.sender &&
          isOfflineFallback == other.isOfflineFallback;

  @override
  int get hashCode =>
      id.hashCode ^
      text.hashCode ^
      sender.hashCode ^
      isOfflineFallback.hashCode;
}
