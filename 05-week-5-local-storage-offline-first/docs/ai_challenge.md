# Dokumentasi AI Prompt Challenge — Minggu 5

## Identitas Mahasiswa

- **Nama:** Agus Prasetyo
- **NIM:** 244107020049
- **Kelas:** TI-3H
- **Program Studi:** D4 Teknik Informatika
- **Mata Kuliah:** Pemrograman Mobile

---

## 1. Prompt yang Digunakan

Sesuai instruksi Codelab Minggu 5 pada bagian *AI Challenge*, prompt berikut diajukan kepada AI Coding Assistant:

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

---

## 2. Output Awal AI

Berikut adalah ringkasan output yang dihasilkan oleh AI Coding Assistant:

### Jawaban Awal AI:
> **Perbandingan Pilihan Local Storage Flutter:**
> 1. **SharedPreferences:** Paling mudah untuk key-value. Cocok untuk boolean dark mode dan timestamp. Tidak cocok untuk daftar catatan karena seluruh list harus di-encode menjadi JSON string raksasa.
> 2. **Hive:** Key-value NoSQL berbasis box biner. Sangat cepat, tidak perlu SQL, bisa menyimpan model kustom dengan TypeAdapter. Kurang optimal untuk query relasional multi-kolom yang rumit.
> 3. **sqflite (SQLite):** Mesin basis data relasional standar industri (ACID-compliant). Sangat tangguh untuk query, sorting, filtering, dan paging. Memerlukan penulisan sintaks SQL manual (string-based) dan tidak memiliki reaktivitas bawaan.
> 4. **Drift:** Abstraksi type-safe di atas SQLite berbasis *code generation*. Mendukung query relasional, stream reaktif otomatis (`watch()`), namun memerlukan dependensi tambahan yang besar (`drift_dev`, `build_runner`).
>
> **Rekomendasi Awal AI:**
> - Preferensi: Gunakan `SharedPreferences` (sederhana, tanpa konfigurasi berat).
> - Catatan: Gunakan `Hive` untuk catatan sederhana atau `Drift` untuk catatan profesional dengan query kompleks.
>
> **Skema Usulan AI untuk 1000+ Catatan (SQLite):**
> ```sql
> CREATE TABLE notes (
>   id INTEGER PRIMARY KEY AUTOINCREMENT,
>   title TEXT NOT NULL,
>   content TEXT,
>   created_at INTEGER
> );
> ```

---

## 3. Analisis Kritis & Evaluasi Verifikasi

Berdasarkan *AI Verification Checklist* pada panduan Codelab, berikut adalah evaluasi mendalam terhadap jawaban AI:

| No | Poin Pemeriksaan Codelab | Hasil Evaluasi | Analisis Kritis & Tindakan Perbaikan |
|:---:|:---|:---:|:---|
| 1 | **Apakah AI menempatkan catatan di SharedPreferences?** | **Lolos** | AI secara tegas menolak menyimpan daftar catatan di `SharedPreferences` karena operasi update parsial, filtering, dan sinkronisasi akan membebani memori (mengharuskan de-serialize seluruh JSON array). |
| 2 | **Apakah skema AI mendukung antrean sync (dirty flag / updated_at)?** | **Ditolak & Diperbaiki** | Skema awal AI hanya berupa CRUD polos (`id`, `title`, `content`, `created_at`). Skema ini sama sekali **tidak memiliki kolom `dirty` dan `updated_at`**, sehingga mustahil mendeteksi antrean perubahan lokal yang belum ter-upload atau menyelesaikan konflik sinkronisasi. Skema diperbaiki dengan menambahkan kolom `updated_at TEXT NOT NULL`, `dirty INTEGER NOT NULL DEFAULT 0`, dan indeks performa. |
| 3 | **Apakah klaim "real-time" didukung stream atau hanya asumsi?** | **Diperbaiki** | AI menyebutkan Drift mendukung real-time stream secara otomatis, namun mengabaikan bahwa pada `sqflite`, reaktivitas dapat dibangun secara elegan menggunakan state management **Riverpod** (`AsyncNotifier` + `ref.invalidate`) tanpa perlu memaksakan dependensi Drift yang rumit. |
| 4 | **Apakah estimasi boilerplate AI masuk akal?** | **Diperbaiki** | AI meremehkan *overhead* instalasi Drift dan Hive. Drift memerlukan `build_runner`, `sqlite3_flutter_libs`, dan perintah generator yang memperlambat waktu build serta rentan konflik dependensi. Sebaliknya, `sqflite` langsung siap pakai dengan zero code-generation. |
| 5 | **Keputusan Final & Justifikasi Teknis** | **Disesuaikan** | Berbeda dari rekomendasi AI yang condong ke Drift/Hive, kami memutuskan menggunakan **`SharedPreferences` untuk preferensi tema/waktu** dan **`sqflite` untuk basis data catatan offline serta cache REST API**. |

---

## 4. Tabel Perbandingan Komprehensif

| Kriteria | SharedPreferences | Hive (NoSQL) | sqflite (SQLite) | Drift (Reactive SQLite) |
|:---|:---|:---|:---|:---|
| **Kompleksitas Query** | Sangat Rendah (Key-Value murni) | Rendah (Pencarian linier / Box key) | **Sangat Tinggi (SQL lengkap, WHERE, ORDER BY, LIMIT, OFFSET, JOIN)** | **Sangat Tinggi (SQL & Dart Fluent API)** |
| **Kebutuhan Relasi** | Tidak Ada | Terbatas (harus manual via HiveList) | **Didukung Penuh (Foreign Key, JOIN, Cascade)** | **Didukung Penuh (Type-safe Relations)** |
| **Reaktivitas (Stream)** | Tidak Ada | Terbatas (`watch()` pada Box) | Melalui Riverpod / ValueNotifier | **Native (`watch()` langsung mengembalikan Stream)** |
| **Type-Safety** | Primitif saja (int, double, bool, String) | Ya (melalui TypeAdapter generator) | Parsial (Map<String, Object?> dengan manual parsing) | **Penuh (Compile-time type checked)** |
| **Ukuran Boilerplate** | **Nol / Sangat Kecil** (langsung pakai) | Sedang (perlu TypeAdapter & register) | **Rendah (hanya openDatabase & SQL string)** | Sangat Tinggi (butuh `build_runner`, file `.g.dart`) |
| **Kemudahan Testing** | Sangat Mudah (Mock / Fake) | Sedang (perlu in-memory directory) | **Sangat Mudah (Constructor Dependency Injection `openDb`)** | Sedang (perlu in-memory database mock) |
| **Kesesuaian Penggunaan** | **Preferensi Aplikasi (Tema, Timestamp)** | Cache objek sederhana tanpa relasi | **Aplikasi Catatan Offline, Sync Queue, Cache API** | Aplikasi Skala Besar dengan relasi kompleks & migrasi berkala |

---

## 5. Skema Optimal untuk 1000+ Catatan Offline-First

Untuk menangani 1.000 hingga puluhan ribu catatan dengan performa tinggi dan dukungan antrean sinkronisasi dua arah, skema SQLite dirancang sebagai berikut:

```sql
-- Tabel Catatan Offline
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);

-- Indeks performa untuk query sorting dan antrean sync
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty) WHERE dirty = 1;

-- Tabel Cache REST API (Cache-First Read)
CREATE TABLE cached_posts (
  id INTEGER PRIMARY KEY,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL
);
```

### Penjelasan Optimasi Skema:
1. **`updated_at TEXT NOT NULL`**: Menyimpan timestamp dalam format ISO 8601 (`YYYY-MM-DDTHH:MM:SS.mmmZ`). Memungkinkan pengurutan catatan terbaru secara leksikografis instan tanpa konversi runtime.
2. **`dirty INTEGER NOT NULL DEFAULT 0`**: Berfungsi sebagai bendera sinkronisasi (*dirty flag*). Nilai `1` menandakan data dibuat/diubah secara lokal dan mengantre untuk di-push ke server. Nilai `0` menandakan data sudah tersinkronisasi bersih.
3. **Indeks Sebagian (*Partial Index*) `idx_notes_dirty`**: Hanya mengindeks baris dengan `dirty = 1`. Saat ada 10.000 catatan namun hanya 3 yang kotor, fungsi `countDirty()` dan query antrean sinkronisasi berjalan dalam $O(1)$ tanpa perlu memindai (*full-table scan*) seluruh basis data.
4. **Pemisahan Cache API (`cached_posts`)**: Menghindari pencampuran entitas catatan pengguna dengan cache respons server JSONPlaceholder.

---

## 6. Aturan Resolusi Konflik (Conflict Resolution)

Dalam arsitektur *Offline-First*, konflik data dapat terjadi jika pengguna mengubah catatan yang sama di dua perangkat berbeda saat offline. Pada implementasi ini, ditetapkan aturan **Last-Write-Wins (LWW)**:

$$\text{Pemenang} = \max(\text{lokal.updated\_at}, \text{remote.updated\_at})$$

1. **Kasus 1 (Lokal Lebih Baru):** Jika `lokal.updated_at > remote.updated_at`, catatan lokal diunggah dan menimpa versi remote di server.
2. **Kasus 2 (Remote Lebih Baru):** Jika server memiliki rekaman dengan `remote.updated_at > lokal.updated_at`, perubahan server diterima ke database SQLite lokal dan `dirty` disetel kembali ke `0`.
3. **Penyelesaian Lokal:** Setiap mutasi lokal (tambah/edit) otomatis memperbarui `updated_at = DateTime.now()` dan menyetel `dirty = 1`.

---

## 7. Kesimpulan Keputusan Teknis

1. **`SharedPreferences`** dipilih untuk preferensi aplikasi primitif (`dark_mode` dan `last_opened_at`) karena tidak membutuhkan skema relasional, sangat cepat, dan terisolasi dari siklus hidup data bisnis.
2. **`SQLite (sqflite)`** dipilih untuk koleksi catatan dan antrean sinkronisasi karena stabilitas, dukungan transaksi ACID, indexing, dan kemampuan query relasional tanpa overhead *code-generation*.
3. **`Riverpod`** melengkapi `sqflite` dengan menyediakan layer reaktivitas deklaratif yang bersih (`AsyncNotifier`), menangani state transisi (loading, error, empty, data), dan memudahkan penulisan *unit test* terisolasi menggunakan `FakeNoteRepository`.
