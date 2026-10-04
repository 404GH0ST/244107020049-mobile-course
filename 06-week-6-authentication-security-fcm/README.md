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

---

## Praktikum 2: Firebase, Permission, dan Token Lifecycle

### Deskripsi Implementasi

`PushService` meminta permission Android 13+, mengambil token FCM, dan mendaftarkannya melalui `POST /devices`. Listener `onTokenRefresh` memanggil registrasi yang sama. UI hanya menampilkan 12 karakter awal token. Mode default menggunakan adapter backend simulasi; kontrak endpoint produksi akan didokumentasikan di `docs/`.

Konfigurasi Firebase pengguna dan pembuktian penerimaan pesan masih menunggu setup project.

---

## Praktikum 3: App State, Deep Link, dan Topic Messaging

### Deskripsi Implementasi

- Foreground: `onMessage` menampilkan local notification untuk payload gabungan; klik meneruskan rute ke GoRouter.
- Background: Android menampilkan notification payload; `onMessageOpenedApp` menangani klik.
- Terminated: `getInitialMessage` dikonsumsi setelah router siap.
- Background handler top-level memakai `@pragma('vm:entry-point')`, tanpa BuildContext atau Riverpod.
- Subscribe/unsubscribe `pengumuman-kampus` dari UI, dan unsubscribe saat sesi logout.
- Data-only dicatat tanpa banner. Navigasi hanya memakai rute internal yang diizinkan.

### Matriks Pengujian

| State | Yang diharapkan | Hasil |
| :--- | :--- | :--- |
| Foreground | Banner lokal; klik ke `/pengumuman/3` | Menunggu konfigurasi Firebase |
| Background | Banner sistem; klik ke `/pengumuman/3` | Menunggu konfigurasi Firebase |
| Terminated | `getInitialMessage`; membuka `/pengumuman/3` | Menunggu konfigurasi Firebase |
