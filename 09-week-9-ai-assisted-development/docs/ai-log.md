# AI Development Log & Verification Report

**Agus Prasetyo · 244107020049 · TI-3H**
Mata Kuliah: Pemrograman Mobile
Jurusan Teknologi Informasi - Politeknik Negeri Malang
Tanggal: 28 Oktober 2026

---

## 1. Praktikum 1: Prompt dan Context Engineering

### 1.1 Formula 5 Slot

Prompt yang baik membatasi ruang halusinasi AI dengan mendefinisikan 5 slot utama:

| Slot | Parameter | Isi Nyata pada Tugas Ini |
| --- | --- | --- |
| 1. Peran | Senior Flutter Developer | Bertindak sebagai senior Flutter engineer dengan pemahaman Clean Architecture dan Riverpod |
| 2. Konteks | Arsitektur, State Management, Storage | Flutter, Riverpod 3.x, SQLite (`sqflite`), Clean Architecture (presentation -> domain <- data), model `Note` |
| 3. Tugas | Fitur spesifik | Menambahkan fitur pencarian catatan berdasarkan judul (`title`) lengkap dengan Empty State informatif |
| 4. Batas | Batasan arsitektural dan ukuran | Jangan melanggar boundary (domain tidak boleh mengimpor Flutter/SQLite/Dio), tidak memanggil database dari UI widget, maksimal 80 baris |
| 5. Output | Format artefak | Pure domain usecase/function, Riverpod providers, UI widget SearchBar + Empty State, dan 3 test case |

### 1.2 Perbandingan Prompt Buruk vs Prompt Baik

- **Prompt Buruk (Vibe Coding):**
  > *"Buatkan search notes yang keren di Flutter pakai Riverpod."*
  >
  > *Dampak:* AI menghasilkan kode monolitik di dalam satu widget, menggunakan API yang dihalusinasikan, melakukan query database berulang setiap ketikan tombol, dan tidak menyertakan pengujian otomatis.

- **Prompt Baik (Context-Engineered):**
  > *"Peran: Senior Flutter Developer.*  
  > *Konteks: Proyek Flutter Offline Notes dengan Riverpod 3.x dan SQLite. Struktur memisahkan presentation, domain, dan data. Model `Note` memiliki field `int? id, String title, String body, DateTime updatedAt, bool dirty`.*  
  > *Tugas: Buat fitur pencarian catatan berdasarkan judul (case-insensitive) lengkap dengan tampilan Empty State jika tidak ditemukan.*  
  > *Batas: Pisahkan logika penyaringan ke dalam domain usecase murni tanpa dependensi Flutter/SQLite/Dio. Jangan panggil SQLite dari widget. Panjang kode usecase maksimal 80 baris.*  
  > *Output: Usecase Dart murni `filterNotes` / `SearchNotesUseCase`, provider Riverpod `searchQueryProvider` & `filteredNotesProvider`, widget SearchBar & Empty State, serta 3 unit test (query kosong, cocok, dan tidak cocok)."*

### 1.3 Context Engineering dan Keamanan Data

- **Konteks yang Disertakan:**
  1. Struktur folder proyek (`lib/data/`, `lib/pages/`, `lib/widgets/`, `test/`).
  2. Kontrak model `Note` (`lib/data/local/note.dart`) dan repository `NoteRepository` (`lib/data/repositories/note_repository.dart`).
  3. Versi package dari `pubspec.yaml` (`flutter_riverpod: ^3.4.3`, `sqflite: ^2.4.4`, `go_router: ^18.0.1`).
- **Data yang Dilarang Disertakan:**
  - Token otentikasi, API Key, kredensial database, atau seluruh isi repositori secara mentah. Digantikan dengan placeholder string seperti `TOKEN_PLACEHOLDER`.

---

## 2. Praktikum 2: Generate dan Verifikasi Search

### 2.1 Raw AI Prompt

```text
Peran: Senior Flutter Developer
Konteks: Proyek Flutter Offline Notes dengan Riverpod 3.x dan SQLite.
Model Note:
class Note {
  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}
NoteRepository saat ini memiliki method: fetchNotes(), getNoteById(id), addNote(), updateNote(), deleteNote(), countDirty(), markAllSynced().
Tugas: Buat implementasi pencarian judul notes lengkap dengan empty state dan state management Riverpod.
Batas: Domain usecase harus murni tanpa import Flutter/Dio/SQLite. Maksimal 80 baris.
Output: Kode Dart untuk usecase, provider Riverpod, widget search bar, dan unit test.
```

### 2.2 Raw AI Output (Proposal Awal AI)

```dart
// USULAN AWAL AI (Mengandung bug & halusinasi)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart'; // Pelanggaran: import SQLite di presentation/domain!

// Usulan AI 1: Method halusinasi pada repository
Future<List<Note>> searchNotesRepo(WidgetRef ref, String query) async {
  // AI berasumsi NoteRepository memiliki searchNotes(query)
  final repo = ref.read(noteRepositoryProvider);
  return repo.searchNotes(query); // HALUSINASI API!
}

// Usulan AI 2: Filter langsung di widget
class BadSearchWidget extends StatelessWidget {
  final List<Note> notes;
  final String query;
  const BadSearchWidget({super.key, required this.notes, required this.query});

  @override
  Widget build(BuildContext context) {
    // BUG LOGIKA: case-sensitive matching dan tidak mentrim whitespace
    final filtered = notes.where((n) => n.title.contains(query)).toList();
    if (filtered.isEmpty) {
      return Text('Kosong');
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => ListTile(title: Text(filtered[i].title)),
    );
  }
}
```

### 2.3 Verifikasi 6 Langkah

1. **Membaca Tiap Baris:** Mengidentifikasi setiap instruksi yang dihasilkan AI. Terlihat AI mengasumsikan method `repo.searchNotes()` dan melakukan filter case-sensitive.
2. **Cek Import:** Domain usecase tidak boleh mengimpor `flutter`, `sqflite`, atau `dio`. Pada usulan awal, AI mencampur import `sqflite` ke file UI.
3. **Cek API (Grep Bukti):**
   ```bash
   grep -rn "searchNotes" lib/data/repositories/note_repository.dart
   # Hasil: 0 baris ditemukan (Exit 1). NoteRepository tidak memiliki method ini!
   ```
4. **Jalankan `flutter analyze`:** Proposal mentah AI menghasilkan error kompilasi karena method fiktif dan import yang salah.
5. **Tulis Test Bukti (Test Sukses & Gagal):**
   - Menulis unit test untuk membuktikan bug case-sensitive: mencari "belanja" pada catatan berjudul "Belanja Mingguan".
6. **Uji Manual:** Menguji skenario query kosong, query cocok, dan query tidak cocok pada emulator.

### 2.4 Bukti Wajib: Halusinasi & Bug Logika AI

1. **Halusinasi API (`searchNotes`):**
   - *Klaim AI:* AI memanggil `noteRepository.searchNotes(query)`.
   - *Bukti Sangkalan:* `rg "searchNotes" lib/data/repositories/note_repository.dart` menghasilkan 0 kecocokan. Repositori lokal mengeksekusi `fetchNotes()` dan menyimpan catatan di memori; pemanggilan method fiktif menyebabkan kompilasi gagal (`The method 'searchNotes' isn't defined for the class 'NoteRepository'`).
2. **Bug Logika (Case-Sensitive Match & Whitespace):**
   - *Klaim AI:* `notes.where((n) => n.title.contains(query))`.
   - *Bukti Sangkalan:* Jika catatan berjudul "Belanja Mingguan" dan user mencari "belanja", method `String.contains()` mengembalikan `false`. Selain itu, input dengan spasi (" belanja ") gagal mencocokkan judul.
   - *Perbaikan:* Wajib melakukan normalisasi query: `final trimmed = query.trim().toLowerCase();` dan mencocokkan `note.title.toLowerCase().contains(trimmed)`.

---

## 3. Praktikum 3: Debug dan Refactor

### 3.1 Debug dengan Test Merah

1. **Reproduksi:** Memasukkan query huruf kecil "belanja" terhadap catatan "Belanja Mingguan".
2. **Isolasi:** Memisahkan fungsi penyaringan ke dalam pure domain function `filterNotes(List<Note> notes, String query)` di `lib/domain/usecases/search_notes.dart`.
3. **Test Merah:** Menulis test di `test/search_filter_test.dart`:
   ```dart
   test('filter abaikan huruf besar/kecil', () {
     expect(filterNotes(sampleNotes, 'belanja'), hasLength(2));
   });
   ```
   Sebelum normalisasi, test ini gagal (merah, expected 2 but got 0).
4. **Perbaikan Kecil (Test Hijau):**
   ```dart
   List<Note> filterNotes(List<Note> notes, String query) {
     final trimmed = query.trim().toLowerCase();
     if (trimmed.isEmpty) {
       return List<Note>.unmodifiable(notes);
     }
     return notes.where((note) {
       return note.title.toLowerCase().contains(trimmed);
     }).toList();
   }
   ```
   Setelah normalisasi diterapkan, seluruh 7 unit test di `test/search_filter_test.dart` langsung berstatus hijau (lulus).
5. **Catatan Akar Masalah:** String comparison di Dart bersifat case-sensitive secara default; query input dari keyboard mobile seringkali diawali huruf kapital otomatis atau memiliki trailing space.

### 3.2 Refactor ke Layer yang Benar

Arsitektur Clean Architecture yang diterapkan:

```text
Widget (UI saja)
  └── lib/pages/notes_page.dart (_SearchNotesHeader, SearchEmptyState)
       ↓
Notifier (State saja)
  └── searchQueryProvider & filteredNotesProvider (Riverpod)
       ↓
Use Case (Aturan filter domain murni)
  └── lib/domain/usecases/search_notes.dart (filterNotes, SearchNotesUseCase)
       ↓
Repository (Persistensi data lokal)
  └── lib/data/repositories/note_repository.dart (SQLite)
```

- **Ukuran Fungsi:** Seluruh fungsi dan method widget berada di bawah 40 baris.
- **Pemisahan Concerns:** Tidak ada pemanggilan database (`sqflite`) maupun manipulasi state langsung di dalam widget `build()`.
- **Empty State:** Menggunakan widget terdedikasi `SearchEmptyState` (`lib/widgets/search_empty_state.dart`) yang memberikan feedback visual jelas serta tombol reset pencarian.

---

## 4. AI Challenge & Review

### 4.1 AI Prompt Challenge

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### 4.2 Tabel Temuan Reviewer AI dan Keputusan

| No | Temuan AI | Level | Bukti / Evaluasi Teknis | Keputusan |
| --- | --- | --- | --- | --- |
| 1 | Query dengan whitespace berlebih ("   ") akan dianggap sebagai filter non-empty dan mengembalikan 0 catatan | Blocker | Terbukti benar: query spasi tanpa `.trim()` akan mencari spasi pada judul dan berpotensi menyembunyikan catatan yang valid | **DITERIMA & DIPERBAIKI**: Menambahkan `query.trim().toLowerCase()` dan pengecekan `if (trimmed.isEmpty) return notes;` |
| 2 | Tambahkan tabel Virtual SQLite FTS5 (Full-Text Search) dan query `MATCH` ke dalam SQLite untuk performa search | Saran | Ditolak beralasan teknis: Koleksi offline notes bersifat lokal dalam rentang puluhan hingga ratusan item. Penambahan FTS5 memerlukan migrasi skema SQLite native, re-indexing table, serta kompilasi engine FTS pada native runner. Penyaringan di memori (in-memory filtering) melalui domain usecase murni jauh lebih cepat (O(N)), instan (< 1 ms), dan tidak menambah kompleksitas dependency. | **DITOLAK**: In-memory domain filtering dipertahankan demi kesederhanaan dan kepatuhan boundary |
| 3 | Sediakan tombol reset/clear interaktif pada UI TextField dan Empty State agar user dapat kembali ke daftar awal dengan satu ketukan | Saran | Terbukti benar: UX mobile membutuhkan cara cepat mengosongkan query tanpa harus menekan backspace berulang-ulang | **DITERIMA & DITERAPKAN**: Menambahkan clear icon button pada search bar dan tombol "Reset Pencarian" pada `SearchEmptyState` |

### 4.3 Tabel Keputusan Per File

| File | Peran | Keputusan | Catatan Tindakan |
| --- | --- | --- | --- |
| `lib/domain/usecases/search_notes.dart` | Domain Logic | Dibuat Ulang / Diterima + Refactor | Murni Dart, bebas dari import Flutter/SQLite/Dio, menangani normalisasi string dan case-insensitivity |
| `lib/data/repositories/note_repository.dart` | Repository & State | Diterima + Refactor | Menambahkan `searchQueryProvider` dan `filteredNotesProvider` reaktif tanpa mengubah method persistensi lama |
| `lib/widgets/search_empty_state.dart` | UI Empty State | Dibuat Mandiri | Menampilkan ilustrasi `Icons.search_off_rounded`, pesan informatif menyertakan query, dan tombol reset |
| `lib/pages/notes_page.dart` | Presentation | Diterima + Refactor | Menghubungkan search field ke `searchQueryProvider`, menampilkan `SearchEmptyState`, menjaga panjang method < 40 baris |
| `test/search_filter_test.dart` | Unit Testing | Dibuat Mandiri | 7 unit test komprehensif menguji seluruh branch domain usecase |
| `test/search_notes_widget_test.dart` | Widget Testing | Dibuat Mandiri | 4 widget test menguji interaksi user, empty state, dan tombol reset |

---

## 5. Ringkasan Bukti Mesin

- **Static Analysis (`flutter analyze`):**
  ```text
  Analyzing 09-week-9-ai-assisted-development...
  No issues found! (ran in 2.1s)
  ```
- **Automated Testing (`flutter test`):**
  ```text
  00:00 +15: All tests passed!
  ```
- **Code Formatting (`dart format --set-exit-if-changed .`):**
  ```text
  Formatted 17 files (0 changed) in 0.04 seconds.
  ```
