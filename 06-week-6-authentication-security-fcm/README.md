# Minggu 6: Authentication, Security & FCM

Dokumentasi dan laporan tugas praktikum Minggu 6 mata kuliah Pemrograman Mobile.

## Identitas Mahasiswa

- **Nama:** Agus Prasetyo
- **NIM:** 244107020049
- **Kelas:** TI-3H
- **Mata Kuliah:** Pemrograman Mobile
- **Program Studi:** D4 Teknik Informatika
- **Jurusan:** Teknologi Informasi

---

## Praktikum 1: Authentication dan Secure Storage

### Deskripsi Implementasi

- Login mock sesuai codelab melalui `AuthRepository`, dengan validasi email dan kata sandi minimal 6 karakter. Token mock bukan JWT produksi.
- `TokenStore` menyimpan access dan refresh token hanya di `flutter_secure_storage`.
- `AuthNotifier` membaca sesi tersimpan saat startup, menangani loading/error, login, dan logout.
- GoRouter membatasi akses ke halaman utama dan pengumuman. Tujuan deep link dipertahankan selama login.
- Interceptor Dio menangani 401 dengan satu refresh dan satu retry. Refresh gagal atau retry tetap 401 membersihkan sesi dan mengarahkan ke login.
- `MockCampusAdapter` menyimulasikan API dalam memori untuk demo 401 tanpa backend eksternal; bukan server kampus nyata.

### Tangkapan Layar

Bukti emulator akan ditambahkan setelah aplikasi dijalankan.
