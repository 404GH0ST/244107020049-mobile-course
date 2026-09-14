# Dokumentasi AI Prompt Challenge — Minggu 3

## Identitas Mahasiswa

- Nama: Agus Prasetyo
- NIM: 244107020049
- Kelas: TI-3H
- Program Studi: D4 Teknik Informatika
- Mata Kuliah: Pemrograman Mobile

---

## 1. Prompt yang Digunakan

Berikut adalah prompt spesifik yang diajukan ke AI Coding Assistant:

```text
Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.
```

---

## 2. Output Awal AI

Output boilerplate awal yang dihasilkan oleh AI adalah sebagai berikut:

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model data statistik
class StatItem {
  final String title;
  final String count;
  StatItem(this.title, this.count);
}

// Notifier asinkron
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  @override
  Future<List<StatItem>> build() async {
    return fetchStats();
  }

  Future<List<StatItem>> fetchStats() async {
    await Future.delayed(const Duration(seconds: 2));
    if (Random().nextDouble() < 0.3) {
      throw Exception('Gagal memuat statistik dari server');
    }
    return [
      StatItem('Total Tugas', '12'),
      StatItem('Tugas Selesai', '8'),
      StatItem('Tugas Tertunda', '4'),
    ];
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);

// Halaman ConsumerWidget
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $err'),
              ElevatedButton(
                onPressed: () => ref.refresh(statsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(items[index].title),
            trailing: Text(items[index].count),
          ),
        ),
      ),
    );
  }
}
```

---

## 3. AI Verification Checklist & Temuan Kritis

| No | Poin Pemeriksaan | Status | Catatan Temuan & Analisis |
|:---|:---|:---:|:---|
| 1 | **Immutability State** | **Lolos (Perbaikan)** | State tidak dimutasi langsung (`state.add()` dihindari). Namun data statistik awal bersifat *hardcoded* statis dan tidak tersinkronisasi dengan state nyata dari `todoListProvider`. |
| 2 | **Penggunaan `ref.watch` vs `ref.read`** | **Lolos** | `ref.watch` digunakan tepat di dalam method `build()`. Pemanggilan mutasi/refresh di callback menggunakan event handler. |
| 3 | **Penanganan Ketiga State `AsyncValue`** | **Lolos** | Metode `.when()` menangani `loading`, `error`, dan `data` secara eksplisit, tidak ada kondisi yang diabaikan. |
| 4 | **Deklarasi Tipe Eksplisit & Bebas Duplikasi** | **Lolos** | Tipe generics dideklarasikan secara eksplisit (`AsyncNotifierProvider<StatsNotifier, List<StatItem>>`). |
| 5 | **Penggunaan API Riverpod Modern** | **Perlu Perbaikan** | AI menggunakan `ref.refresh(statsProvider)` yang merupakan alias lama; pada Riverpod 2.x/3.x disarankan menggunakan `ref.invalidate(statsProvider)` atau method eksplisit pada notifier. Model juga belum memanfaatkan `copyWith` dan `const` constructor. |
| 6 | **Hasil `flutter analyze` & `flutter test`** | **Lolos setelah Perbaikan** | Kode awal menghasilkan peringatan linter mengenai konstanta `StatItem`, penggunaan `ref.refresh`, dan test yang flaked karena kegagalan acak 30% tanpa mock/override flag. |

---

## 4. Perbaikan dan Peningkatan yang Dilakukan

1. **Integrasi Data Nyata**: Menghubungkan kalkulasi statistik langsung dengan `todoListProvider` menggunakan `ref.read(todoListProvider)` sehingga data total tugas, tugas selesai, dan tugas aktif selalu akurat sesuai aksi pengguna.
2. **Kontrol Mode Error untuk Demo & Test**: Menambahkan static flag `forceErrorMode` agar UI error dan unit test dapat dipicu secara deterministik tanpa bergantung pada generator acak.
3. **Penyempurnaan UI Material 3**: Mengganti `ListTile` datar dengan `Card` Material 3 yang memiliki ikon tematik, warna indikator, kontras yang terbaca di tema gelap/terang, dan label deskripsi informatif.
4. **Pembersihan Lint & Standar Riverpod**: Mengganti pemanggilan usang dengan `ref.invalidate(statsProvider)` serta menambahkan tombol refresh berbasis `AsyncValue.guard`.
5. **Unit Test yang Andal**: Menyusun unit test terisolasi menggunakan `ProviderContainer` untuk menguji kondisi sukses (`AsyncData`) dan kondisi error (`AsyncError`) tanpa terkena race condition timeout.
