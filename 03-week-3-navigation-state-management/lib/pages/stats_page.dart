import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

/// Halaman Statistik (StatsPage) yang dibangun menggunakan Riverpod `ConsumerWidget`.
///
/// Halaman ini mengamati `statsProvider` yang bertipe `AsyncNotifierProvider`.
/// UI secara komprehensif menangani ketiga kondisi `AsyncValue`:
/// 1. `loading`: menampilkan spinner / indikator progres saat data diambil.
/// 2. `error`: menampilkan pesan kesalahan beserta tombol coba lagi (retry).
/// 3. `data` (success): menampilkan daftar ringkasan statistik (minimal 3 item).
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch digunakan di dalam method build agar widget membangun ulang dirinya
    // secara otomatis saat state asinkron berubah (loading -> data / error).
    final statsAsync = ref.watch(statsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Akademik'),
        actions: [
          // Tombol aksi untuk toggle mode simulasi error (memudahkan demo dan validasi UI)
          IconButton(
            tooltip: StatsNotifier.forceErrorMode == true
                ? 'Mode Error Aktif (Klik untuk Mode Normal)'
                : 'Mode Normal (Klik untuk Simulasikan Error)',
            icon: Icon(
              StatsNotifier.forceErrorMode == true
                  ? Icons.warning_amber_rounded
                  : Icons.cloud_done_outlined,
              color: StatsNotifier.forceErrorMode == true ? Colors.red : null,
            ),
            onPressed: () {
              // Toggle mode error dan segarkan provider
              if (StatsNotifier.forceErrorMode == true) {
                StatsNotifier.forceErrorMode = false;
              } else {
                StatsNotifier.forceErrorMode = true;
              }
              // ref.invalidate membuat provider diinisialisasi ulang dari awal
              ref.invalidate(statsProvider);
            },
          ),
          IconButton(
            tooltip: 'Segarkan data',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // ref.read digunakan di dalam callback event untuk memanggil method Notifier
              ref.read(statsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      // Pola .when() dari AsyncValue untuk menangani loading, error, dan success (data)
      body: statsAsync.when(
        // 1. Kondisi Loading: Tampilkan CircularProgressIndicator dan teks informatif
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                'Mengambil data statistik dari server...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Simulasi latensi jaringan (2 detik)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),

        // 2. Kondisi Error: Tampilkan pesan kesalahan dan tombol retry
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Terjadi Kesalahan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // Ketika tombol coba lagi ditekan, pulihkan mode normal lalu invalidate provider
                    StatsNotifier.forceErrorMode = false;
                    ref.invalidate(statsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),

        // 3. Kondisi Success: Tampilkan daftar item statistik menggunakan ListView
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.read(statsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 14.0),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.value,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Perbarui Statistik',
        onPressed: () => ref.read(statsProvider.notifier).refresh(),
        child: const Icon(Icons.sync),
      ),
    );
  }
}
