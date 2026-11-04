import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_chat_provider.dart';

class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});
  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save({bool remove = false}) async {
    if (!remove && _controller.text.trim().isEmpty) {
      setState(() => _error = 'Masukkan kunci API.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notifier = ref.read(apiKeyStatusProvider.notifier);
      if (remove) {
        await notifier.clearKey();
      } else {
        await notifier.setKey(_controller.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remove
                ? 'Kunci API berhasil dihapus.'
                : 'Kunci API Gemini tersimpan aman di SecureStorage.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Penyimpanan kunci gagal. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Kunci API Gemini'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kunci disimpan pada secure storage perangkat. Kunci dikirim hanya ke Google saat memakai AI. Gunakan kunci praktikum dengan kuota terbatas.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('api_key_dialog_field'),
              controller: _controller,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Google Gemini API Key',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (ref.watch(apiKeyStatusProvider).value == true)
          TextButton(
            onPressed: _busy ? null : () => _save(remove: true),
            child: const Text('Hapus Kunci'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    ),
  );
}
