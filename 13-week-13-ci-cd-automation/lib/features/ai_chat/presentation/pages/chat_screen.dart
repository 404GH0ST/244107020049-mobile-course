import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/record_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _mediaBusy = false;
  static const _prompts = [
    'Jadwal kuliah hari Senin?',
    'Bagaimana pengisian KRS?',
    'Panduan pembayaran UKT',
    'Informasi beasiswa',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _input.text;
    if (SendChatMessage.validate(text) == null) {
      _input.clear();
      FocusScope.of(context).unfocus();
    }
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<bool> _consent({Widget? preview}) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tinjau sebelum kirim'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?preview,
                const Text(
                  'Gambar atau suara akan dikirim ke Google Gemini. Jangan sertakan KTM, NIK, alamat, nomor telepon, kata sandi, atau data pribadi orang lain. Kirim hanya jika Anda berhak membagikannya. Biaya dan kebijakan penyedia berlaku.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Setuju dan kirim'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _image() async {
    setState(() => _mediaBusy = true);
    try {
      final selection =
          await showModalBottomSheet<({ImageSource source, bool describe})>(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gambar dan OCR',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih gambar tanpa data pribadi. Anda dapat meninjaunya sebelum dikirim.',
                    ),
                    for (final describe in [false, true])
                      for (final source in [
                        ImageSource.gallery,
                        ImageSource.camera,
                      ])
                        ListTile(
                          leading: Icon(
                            source == ImageSource.gallery
                                ? Icons.photo_outlined
                                : Icons.camera_alt_outlined,
                          ),
                          title: Text(
                            '${describe ? 'Deskripsikan' : 'Ekstrak teks'} dari ${source == ImageSource.gallery ? 'galeri' : 'kamera'}',
                          ),
                          onTap: () => Navigator.pop(ctx, (
                            source: source,
                            describe: describe,
                          )),
                        ),
                  ],
                ),
              ),
            ),
          );
      if (selection == null || !mounted) return;
      final file = await ImagePicker().pickImage(
        source: selection.source,
        maxWidth: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 4 * 1024 * 1024) {
        _notice('Pilih gambar maksimal 4 MB.');
        return;
      }
      if (!mounted) return;
      final consent = await _consent(
        preview: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Image.file(
            File(file.path),
            height: 160,
            errorBuilder: (_, _, _) => const Text(
              'Pratinjau tidak tersedia. Batalkan jika isi gambar belum dipastikan.',
            ),
          ),
        ),
      );
      if (consent && mounted) {
        await ref
            .read(chatNotifierProvider.notifier)
            .processMedia(file.path, describe: selection.describe);
      }
    } catch (_) {
      _notice(
        'Gambar tidak dapat dibuka. Periksa izin atau pilih gambar lain.',
      );
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  Future<void> _voice() async {
    setState(() => _mediaBusy = true);
    String? path;
    try {
      path = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const RecordSheet(),
      );
      if (path == null || !mounted) return;
      if (!await _consent() || !mounted) return;
      final text = await ref
          .read(chatNotifierProvider.notifier)
          .processMedia(path, audio: true);
      if (text != null && mounted) {
        _input.text = text;
        _notice(
          'Transkripsi siap. Periksa dan hapus data pribadi sebelum menekan Kirim.',
        );
      }
    } catch (_) {
      _notice('Rekaman gagal diproses. Coba lagi.');
    } finally {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatNotifierProvider);
    final keyState = ref.watch(apiKeyStatusProvider);
    final hasKey = keyState.value ?? false;
    final colors = Theme.of(context).colorScheme;
    final busy = chat.isLoading || _mediaBusy;
    ref.listen(chatNotifierProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten AI Kampus'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Kunci API',
            icon: const Icon(Icons.key_outlined),
            onPressed: busy
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) => const ApiKeyDialog(),
                  ),
          ),
          IconButton(
            tooltip: 'Bersihkan Obrolan',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: busy
                ? null
                : () => ref.read(chatNotifierProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: colors.surfaceContainerLow,
                  child: Text(
                    keyState.isLoading
                        ? 'Memeriksa kunci API...'
                        : hasKey
                        ? 'Kunci API tersimpan. Koneksi diperiksa saat mengirim.'
                        : 'Mode Offline Fallback. Atur kunci API untuk layanan cloud.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (chat.errorMessage != null)
                  MaterialBanner(
                    content: Text(chat.errorMessage!),
                    actions: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => ref
                                  .read(chatNotifierProvider.notifier)
                                  .handleErrorAction(chat.canRetry),
                        child: Text(chat.canRetry ? 'Coba lagi' : 'Tutup'),
                      ),
                    ],
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(20),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) =>
                        _MessageBubble(message: chat.messages[i]),
                  ),
                ),
                if (chat.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Asisten AI sedang menyusun jawaban...'),
                        ),
                      ],
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final prompt in _prompts)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(prompt),
                            onPressed: busy ? null : () => _send(prompt),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      TextField(
                        key: const Key('chat_input_field'),
                        controller: _input,
                        enabled: !busy,
                        maxLength: 500,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: busy ? null : (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Tanya panduan kampus...',
                          border: OutlineInputBorder(),
                          counterText: 'Maksimal 500 karakter. Jangan sertakan data pribadi.',
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'OCR Dokumen',
                            icon: const Icon(Icons.document_scanner_outlined),
                            onPressed: busy ? null : _image,
                          ),
                          IconButton(
                            tooltip: 'Speech-to-Text',
                            icon: const Icon(Icons.mic_none_outlined),
                            onPressed: busy ? null : _voice,
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            key: const Key('chat_send_button'),
                            onPressed: busy ? null : () => _send(),
                            icon: const Icon(Icons.send_outlined),
                            label: const Text('Kirim'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final user = message.sender == MessageSender.user;
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: user ? colors.primaryContainer : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user ? 'Anda' : 'Asisten',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(
                color: user ? colors.onPrimaryContainer : colors.onSurface,
                height: 1.45,
              ),
            ),
            if (message.isOfflineFallback)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Panduan lokal offline',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
