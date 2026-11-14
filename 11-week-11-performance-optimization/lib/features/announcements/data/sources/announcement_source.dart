abstract interface class AnnouncementDataSource {
  Future<List<Map<String, Object?>>> fetch({int offset = 0, int limit = 20});
  Future<Map<String, Object?>> get(String id);
}

// Feed contoh kampus di memori dengan latensi jaringan simulasi.
// Jumlah data dibuat realistis agar skenario profiling Minggu 11 terukur.
class AnnouncementSource implements AnnouncementDataSource {
  AnnouncementSource({
    this.total = 240,
    this.latency = const Duration(milliseconds: 400),
  });

  final int total;
  final Duration latency;
  int requests = 0;

  static const _categories = [
    'Akademik',
    'Kemahasiswaan',
    'Beasiswa',
    'Laboratorium',
    'Keuangan',
    'Karier',
  ];
  static const _topics = [
    'Jadwal kuliah berubah',
    'Pengisian KRS semester genap',
    'Pendaftaran beasiswa prestasi',
    'Perawatan server laboratorium',
    'Batas pembayaran UKT',
    'Job fair mitra industri',
    'Seminar proposal tugas akhir',
    'Peminjaman ruang kegiatan',
  ];

  Map<String, Object?> _row(int n) {
    final category = _categories[n % _categories.length];
    final day = (n % 28) + 1;
    return {
      'id': '$n',
      'title': n == 3 ? 'Jadwal kuliah berubah' : _topics[n % _topics.length],
      'subtitle': '$category • ${day.toString().padLeft(2, '0')}/11/2026 • #$n',
      'body': n == 3
          ? 'Kelas Mobile pindah ke Ruang A2 jam 13.00. Silakan menyesuaikan jadwal perkuliahan.'
          : 'Informasi $category nomor $n untuk mahasiswa JTI. '
                'Periksa kanal resmi kampus untuk detail terbaru.',
    };
  }

  @override
  Future<List<Map<String, Object?>>> fetch({
    int offset = 0,
    int limit = 20,
  }) async {
    requests++;
    await Future<void>.delayed(latency);
    final end = (offset + limit).clamp(0, total);
    return [for (var n = offset + 1; n <= end; n++) _row(n)];
  }

  @override
  Future<Map<String, Object?>> get(String id) async {
    requests++;
    await Future<void>.delayed(latency);
    final n = int.tryParse(id);
    if (n == null || n < 1 || n > total) {
      return {
        'id': id,
        'title': 'Informasi kampus',
        'subtitle': 'Contoh pengumuman #$id',
        'body': 'Pengumuman tidak ditemukan pada feed contoh.',
      };
    }
    return _row(n);
  }
}
