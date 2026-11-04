abstract interface class AnnouncementDataSource {
  Future<List<Map<String, Object?>>> fetch();
  Future<Map<String, Object?>> get(String id);
}

// Data contoh dari widget Minggu 6. Tidak menambah API atau fitur baru.
class AnnouncementSource implements AnnouncementDataSource {
  static const _body =
      'Kelas Mobile pindah ke Ruang A2 jam 13.00. Silakan menyesuaikan jadwal perkuliahan.';

  @override
  Future<List<Map<String, Object?>>> fetch() async => [await get('3')];

  @override
  Future<Map<String, Object?>> get(String id) async => {
    'id': id,
    'title': id == '3' ? 'Jadwal kuliah berubah' : 'Informasi kampus',
    'subtitle': 'Contoh pengumuman #$id',
    'body': _body,
  };
}
