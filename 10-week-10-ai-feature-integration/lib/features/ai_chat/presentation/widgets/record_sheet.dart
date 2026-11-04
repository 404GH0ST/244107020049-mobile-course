import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordSheet extends StatefulWidget {
  const RecordSheet({super.key});
  @override
  State<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<RecordSheet> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _busy = false;
  int _seconds = 0;
  Timer? _timer;
  String? _error;
  String? _path;
  bool _handedOff = false;
  @override
  void dispose() {
    _timer?.cancel();
    final path = _path;
    final handedOff = _handedOff;
    unawaited(
      _recorder.dispose().then((_) async {
        if (!handedOff && path != null) {
          try {
            await File(path).delete();
          } catch (_) {}
        }
      }),
    );
    super.dispose();
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      if (_recording) {
        _timer?.cancel();
        final path = await _recorder.stop();
        if (!mounted) return;
        _handedOff = true;
        Navigator.pop(context, path);
        return;
      }
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          setState(
            () => _error = 'Izin mikrofon ditolak. Aktifkan melalui pengaturan perangkat atau gunakan input teks.',
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      if (!mounted) return;
      _path =
          '${dir.path}/campus_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: _path!,
      );
      if (!mounted) return;
      setState(() => _recording = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= 30) unawaited(_toggle());
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Mikrofon tidak tersedia. Gunakan input teks atau coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Speech-to-Text (Input Suara)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Rekam maksimal 30 detik tanpa data pribadi. Setelah berhenti, Anda dapat menyetujui pengiriman ke Gemini. Transkripsi dapat diedit sebelum dikirim sebagai chat.',
          ),
          const SizedBox(height: 20),
          Text(
            _recording
                ? 'Merekam: $_seconds / 30 detik'
                : 'Mikrofon belum merekam',
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _toggle,
            icon: Icon(_recording ? Icons.stop : Icons.mic),
            label: Text(_recording ? 'Selesai merekam' : 'Mulai merekam'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    ),
  );
}
