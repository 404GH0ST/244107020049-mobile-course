# Minggu 5: Local Storage & Offline First

Dokumentasi dan laporan tugas praktikum Minggu 5 mata kuliah Pemrograman Mobile.

## Identitas Mahasiswa

- **Nama:** Agus Prasetyo
- **NIM:** 244107020049
- **Kelas:** TI-3H
- **Mata Kuliah:** Pemrograman Mobile
- **Program Studi:** D4 Teknik Informatika
- **Jurusan:** Teknologi Informasi

---

## Praktikum 1: SharedPreferences (Penyimpanan Key-Value)

### Deskripsi Implementasi

Pada praktikum pertama, saya mengimplementasikan penyimpanan lokal berbasis *key-value* menggunakan package `shared_preferences` yang diintegrasikan dengan arsitektur Repository Pattern dan state management `flutter_riverpod`:

- **Inisialisasi Proyek & Dependensi:** Proyek dikonfigurasi dengan menambahkan dependensi utama pada `pubspec.yaml`, meliputi `flutter_riverpod` untuk manajemen state reaktif, `shared_preferences` untuk penyimpanan preferensi lokal sederhana, serta `sqflite` dan `path` untuk persiapan basis data relasional pada praktikum berikutnya.
- **Penerapan Repository Pattern (`lib/data/prefs.dart`):**
  - Seluruh akses I/O ke penyimpanan *key-value* dipusatkan ke dalam kelas `PrefsRepository`. Hal ini memastikan UI tidak memanggil `SharedPreferences` secara langsung (*Separation of Concerns*).
  - Menggunakan konstanta privat `_darkModeKey = 'dark_mode'` dan `_lastOpenedKey = 'last_opened_at'` untuk menghindari kesalahan pengetikan string (*typo-prone*).
  - Method `getDarkMode()`: Membaca preferensi mode gelap secara asinkron dengan nilai default fallback `false` (`prefs.getBool(_darkModeKey) ?? false`).
  - Method `setDarkMode(bool value)`: Menyimpan preferensi boolean mode gelap ke penyimpanan persisten perangkat.
  - Method `markOpenedNow()`: Menyimpan rekaman waktu aplikasi dibuka saat ini dalam format standar ISO 8601 (`DateTime.now().toIso8601String()`).
  - Method `getLastOpened()`: Membaca kembali string waktu terakhir aplikasi dibuka untuk kebutuhan diagnostik atau personalisasi antarmuka.
- **Pengelolaan State dengan Riverpod (`lib/pages/settings_page.dart`):**
  - Mendaftarkan repository melalui provider dependensi: `final prefsRepositoryProvider = Provider((ref) => PrefsRepository());`.
  - Mengelola state preferensi tema gelap/terang secara asinkron menggunakan `AsyncNotifierProvider<DarkModeNotifier, bool>`:
    - **`build()`:** Mengembalikan `Future<bool>` dengan membaca preferensi tema yang tersimpan di `PrefsRepository` melalui `ref.watch(prefsRepositoryProvider).getDarkMode()`.
    - **`toggle()`:** Membalikkan status tema (`!(state.value ?? false)`), menetapkan state ke `AsyncLoading()` untuk memberikan respons visual pada UI, dan memanfaatkan `AsyncValue.guard()` untuk menangani penyimpanan preferensi ke repository secara aman tanpa blok try/catch manual.
- **Pencegahan Kesalahan Umum & Arsitektur Bersih:**
  - Menghindari *anti-pattern* pemanggilan `SharedPreferences.getInstance()` di dalam method `build()` widget, yang dapat memicu freeze/jank rendering UI dan menyulitkan pengujian unit terisolasi.
  - Menegaskan batas tanggung jawab penyimpanan: `SharedPreferences` khusus digunakan untuk preferensi konfigurasi primitif kecil (key-value), bukan untuk data koleksi seperti catatan atau daftar entitas.
