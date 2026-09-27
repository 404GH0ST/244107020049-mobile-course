import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';
import '../data/sync.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>((ref) async {
  return ref.watch(prefsRepositoryProvider).getLastOpened();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Preferensi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'SharedPreferences (Key-Value)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Mode Gelap (Dark Mode)'),
                  subtitle: const Text('Simpan preferensi tema aplikasi secara lokal'),
                  secondary: Icon(
                    darkModeAsync.value == true
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  value: darkModeAsync.value ?? false,
                  onChanged: darkModeAsync.isLoading
                      ? null
                      : (_) => ref.read(darkModeProvider.notifier).toggle(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Terakhir Dibuka'),
                  subtitle: lastOpenedAsync.when(
                    data: (timestamp) => Text(
                      timestamp != null
                          ? _formatTimestamp(timestamp)
                          : 'Belum pernah dibuka sebelumnya',
                    ),
                    loading: () => const Text('Membaca preferensi...'),
                    error: (err, _) => Text('Error: $err'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Simulasi Jaringan (Offline-First)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Simulasi Mode Offline (Force Offline)'),
                  subtitle: const Text(
                    'Uji ketahanan aplikasi saat tidak ada akses jaringan tanpa perlu mematikan Wi-Fi perangkat',
                  ),
                  secondary: Icon(
                    ref.watch(forceOfflineProvider)
                        ? Icons.cloud_off
                        : Icons.cloud_queue,
                    color: ref.watch(forceOfflineProvider) ? Colors.orange : null,
                  ),
                  value: ref.watch(forceOfflineProvider),
                  onChanged: (val) {
                    ref.read(forceOfflineProvider.notifier).setOffline(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Arsitektur Local Storage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• SharedPreferences: Dikhususkan untuk nilai primitif kecil seperti tema gelap/terang dan waktu terakhir dibuka.\n'
                    '• SQLite (sqflite): Menyimpan koleksi catatan terstruktur, flag sinkronisasi (dirty), dan cache respons REST API.\n'
                    '• Riverpod: Mengelola state asinkron secara reaktif tanpa memanggil I/O langsung dari widget tree.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final year = dt.year.toString().padLeft(4, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute:$second';
    } catch (_) {
      return isoString;
    }
  }
}
