import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stat_item.dart';
import 'todo_provider.dart';

/// Notifier asinkron untuk mengelola data statistik aplikasi ToDo.
///
/// Memanfaatkan `AsyncNotifier` dari Riverpod untuk memodelkan tiga state:
/// - `AsyncLoading`: proses pengambilan data sedang berjalan.
/// - `AsyncError`: terjadi kegagalan (misalnya koneksi putus atau server error).
/// - `AsyncData`: data siap ditampilkan ke UI.
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  /// Flag konfigurasi untuk memaksa mode simulasi error (memudahkan pengujian dan demo UI).
  static bool? forceErrorMode;

  @override
  Future<List<StatItem>> build() async {
    // Memanggil fungsi fetch yang mensimulasikan pengambilan data dari server
    return _fetchStats();
  }

  /// Fungsi internal untuk mensimulasikan latency jaringan dan kegagalan acak.
  Future<List<StatItem>> _fetchStats() async {
    // Simulasi delay jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Menentukan apakah request gagal:
    // Jika forceErrorMode di-set, ikuti nilainya.
    // Jika null, simulasikan kegagalan acak dengan probabilitas ~30%.
    final shouldFail = forceErrorMode ?? (Random().nextInt(100) < 30);

    if (shouldFail) {
      throw Exception('Gagal memuat data statistik dari server (Koneksi timeout 504)');
    }

    // Mengambil snapshot daftar todo saat ini untuk menghitung statistik riil
    final todos = ref.read(todoListProvider);
    final total = todos.length;
    final completed = todos.where((t) => t.done).length;
    final active = total - completed;
    final rate = total == 0 ? 0 : ((completed / total) * 100).round();

    // Mengembalikan minimal 3 item statistik sesuai spesifikasi challenge
    return [
      StatItem(
        label: 'Total Tugas',
        value: '$total',
        description: 'Seluruh tugas yang tercatat dalam sistem',
        icon: Icons.assignment_outlined,
        color: Colors.blue,
      ),
      StatItem(
        label: 'Tugas Selesai',
        value: '$completed',
        description: 'Tugas yang telah ditandai tuntas',
        icon: Icons.check_circle_outline,
        color: Colors.green,
      ),
      StatItem(
        label: 'Tugas Belum Selesai',
        value: '$active',
        description: 'Tugas aktif yang masih perlu dikerjakan',
        icon: Icons.pending_actions_outlined,
        color: Colors.orange,
      ),
      StatItem(
        label: 'Tingkat Penyelesaian',
        value: '$rate%',
        description: 'Rasio kemajuan penyelesaian tugas mahasiswa',
        icon: Icons.donut_large_outlined,
        color: Colors.purple,
      ),
    ];
  }

  /// Memperbarui data statistik secara eksplisit dengan membungkus eksekusi
  /// menggunakan AsyncValue.guard untuk menangkap error secara otomatis.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

/// Provider global bertipe AsyncNotifierProvider untuk mengakses StatsNotifier.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
