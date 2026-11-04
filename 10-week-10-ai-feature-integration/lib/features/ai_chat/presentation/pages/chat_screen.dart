import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../providers/ai_chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _suggestedPrompts = [
    'Jadwal kuliah hari Senin?',
    'Bagaimana pengisian KRS?',
    'Kapan batas bayar UKT?',
    'Lokasi Gedung Kuliah Bersama?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;
    if (presetText == null) {
      _textController.clear();
    }
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showApiKeyDialog(BuildContext context) {
    final currentKey = ref.read(apiKeyStatusProvider);
    final keyController = TextEditingController(text: currentKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.amber),
            SizedBox(width: 8),
            Text('Kunci API Gemini'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kunci disimpan aman di FlutterSecureStorage perangkat dan tidak pernah diekspos ke publik.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('api_key_dialog_field'),
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Google Gemini API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (currentKey != null)
            TextButton(
              onPressed: () {
                ref.read(apiKeyStatusProvider.notifier).clearKey();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kunci API berhasil dihapus.')),
                );
              },
              child: const Text(
                'Hapus Kunci',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                ref.read(apiKeyStatusProvider.notifier).setKey(key);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kunci API Gemini tersimpan aman di SecureStorage.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showOcrDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OCR Dokumen Kampus',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih jenis dokumen untuk diekstraksi teksnya oleh modul Vision OCR:',
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.badge_outlined, color: Colors.blue),
                title: const Text('Scan Kartu Tanda Mahasiswa (KTM)'),
                subtitle: const Text('Ekstraksi NIM, Nama, dan Program Studi'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(chatNotifierProvider.notifier)
                      .sendOcr('ktm mahasiswa');
                  _scrollToBottom();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: Colors.green,
                ),
                title: const Text('Scan Papan Pengumuman / Jadwal Ujian'),
                subtitle: const Text(
                  'Ekstraksi tanggal ujian dan ruang perkuliahan',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(chatNotifierProvider.notifier)
                      .sendOcr('pengumuman jadwal ujian');
                  _scrollToBottom();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSttDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speech-to-Text (Input Suara)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Simulasi input suara mahasiswa untuk diterjemahkan ke teks:',
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.deepPurple),
                title: const Text(
                  '"Kapan jadwal pengisian KRS semester depan?"',
                ),
                subtitle: const Text('Pertanyaan suara akademik'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(chatNotifierProvider.notifier)
                      .sendVoice('jadwal krs');
                  _scrollToBottom();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none, color: Colors.teal),
                title: const Text('"Bagaimana prosedur penyesuaian UKT?"'),
                subtitle: const Text('Pertanyaan suara administrasi'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(chatNotifierProvider.notifier)
                      .sendVoice('bayar ukt');
                  _scrollToBottom();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final apiKey = ref.watch(apiKeyStatusProvider);
    final theme = Theme.of(context);

    ref.listen<ChatState>(chatNotifierProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asisten AI Kampus', style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: apiKey != null ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  apiKey != null
                      ? 'Mode Gemini Cloud'
                      : 'Mode Offline Fallback',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Kunci API',
            icon: Icon(
              apiKey != null ? Icons.key : Icons.key_off_outlined,
              color: apiKey != null ? Colors.amber : null,
            ),
            onPressed: () => _showApiKeyDialog(context),
          ),
          IconButton(
            tooltip: 'Bersihkan Obrolan',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () =>
                ref.read(chatNotifierProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return _ChatMessageBubble(message: message);
              },
            ),
          ),
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Asisten AI sedang menyusun jawaban...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          // Suggested prompts horizontally
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                for (final prompt in _suggestedPrompts)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.lightbulb_outline, size: 16),
                      onPressed: chatState.isLoading
                          ? null
                          : () => _handleSend(prompt),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'OCR Dokumen',
                  icon: const Icon(Icons.document_scanner_outlined),
                  onPressed: chatState.isLoading
                      ? null
                      : () => _showOcrDialog(context),
                ),
                IconButton(
                  tooltip: 'Speech-to-Text',
                  icon: const Icon(Icons.mic_none_outlined),
                  onPressed: chatState.isLoading
                      ? null
                      : () => _showSttDialog(context),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('chat_input_field'),
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Tanyakan sesuatu ke asisten...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('chat_send_button'),
                  icon: const Icon(Icons.send_rounded),
                  onPressed: chatState.isLoading ? null : () => _handleSend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == MessageSender.user;
    final isSystem = message.sender == MessageSender.system;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  if (message.isOfflineFallback) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Offline Campus Knowledge',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
