# Bukti Verifikasi Praktikum Minggu 6

Tanggal: 4–5 Oktober 2026. Aplikasi Android dijalankan melalui `flutter run -d emulator-5554` pada AVD Pixel 10, Android 17 / API 37, ABI arm64-v8a, dengan Google Play Services. Flutter 3.47.6, Dart 3.13.5. Skala tampilan emulator disesuaikan saat melengkapi bukti agar kontrol dan teks yang dibuktikan terbaca penuh. Dua puluh tiga screenshot aplikasi berasal dari `adb exec-out screencap -p`, berupa frame emulator utuh 1080 × 2424; bukan rekonstruksi gambar. Dua screenshot terminal `flutter_analyze.png` dan `flutter_test.png` menggunakan gambar hasil eksekusi yang diberikan pengguna, disalin tanpa perubahan. Tiga gambar tambahan pengiriman Firebase Console diberikan pengguna dan disalin tanpa perubahan; gambar panel notifikasi dan detail merupakan cuplikan tampilan, bukan frame emulator utuh.

## Authentication dan Security

- Login kosong menampilkan validasi email dan minimal enam karakter kata sandi.
- Login contoh `demo@kampus.test` berhasil tanpa Firebase Auth.
- Tombol demo request menunjukkan `401 → refresh sekali → retry 200`.
- Ketika refresh sengaja dikosongkan, request berikutnya membersihkan sesi dan mengarahkan ke login.
- Sesi dibaca kembali setelah startup, sementara clear data menghilangkan sesi tersimpan.
- Interceptor tidak mencetak token atau object request yang membawa Authorization.

## FCM App States — Pengujian Awal

| State | Tindakan | Bukti log awal | Hasil klik |
| :--- | :--- | :--- | :--- |
| Foreground | Aplikasi terbuka, kirim payload gabungan | `foreground id=0:1791118272998253%f6700c7bf6700c7b` | `foreground-click route=/pengumuman/3`, halaman #3 |
| Background | Tekan Home, kirim payload sama | `background id=0:1791118329583783%f6700c7bf6700c7b` | `background-click`, halaman #3 |
| Terminated | Swipe-close dari recent apps; cached process kemudian dihentikan dengan `am kill` sebelum klik untuk cold start | `background id=0:1791118388737238%f6700c7bf6700c7b`; proses main baru saat klik | `terminated-click` lewat `getInitialMessage`, halaman #3 |

Tidak memakai `am force-stop` untuk pengujian FCM: force-stop menempatkan aplikasi dalam keadaan stopped dan dapat menghalangi pengiriman. Pada pengujian terminated, swipe-close mengakhiri aktivitas/engine Flutter; Android masih mempertahankan cached process untuk background handler, kemudian `am kill` memastikan cold start saat klik. PID berubah dari 7643 ke 8473. Kedua token auth masih tersimpan sehingga tujuan dapat dibuka tanpa login ulang.

Payload gabungan yang sama ada di `fcm_payload.json`. Pengiriman pertama FCM HTTP v1 diterima dengan status 200. ID pengiriman awal: foreground `-4598962921353808995`, background `-3139577468318954849`, terminated `3422254174194411373`. ID respons pengiriman tidak sama dengan messageId yang diterima perangkat.

Screenshot panel Android menampilkan kartu local notification pada foreground dan kartu sistem pada background/terminated. Screenshot halaman tujuan diambil setelah mengetuk kartu, bukan setelah membuka daftar pengumuman secara manual.

## Pengambilan Ulang Screenshot dan Maknanya

Audit visual dilanjutkan pada 4–5 Oktober 2026. Tiga pengujian dikirim ulang menggunakan payload gabungan yang sama agar setiap baris README memperlihatkan kondisi aplikasi, kartu notifikasi, dan halaman sesudah klik. Gambar detail ditunggu sampai halaman selesai tampil; gambar panel ditunggu sampai animasi selesai dan kartu pesan ada. Bukti pengujian awal tetap berada dalam log, sedangkan screenshot matriks sekarang berasal dari pengambilan ulang berikut:

| State | Kondisi yang diperiksa | MessageId sesuai screenshot | Event klik |
| :--- | :--- | :--- | :--- |
| Foreground | Aplikasi aktif, event foreground terlihat di halaman utama | `0:1791132787771238%f6700c7bf6700c7b` | 4 Oktober 23:53:10 WIB, `foreground-click` |
| Background | Home ditekan sebelum pengiriman, proses masih ada | `0:1791132534356679%f6700c7bf6700c7b` | 4 Oktober 23:48:55 WIB, `background-click` |
| Terminated | Semua task ditutup, recent apps menampilkan No recent items, pidof tidak menghasilkan PID sebelum kirim | `0:1791133611581839%f6700c7bf6700c7b` | 5 Oktober 00:07:00 WIB, `terminated-click` |

Pada pengambilan ulang terminated, proses 9223 muncul saat FCM menjalankan background handler; proses tersebut kemudian juga membuka UI ketika kartu diklik. Bukti tidak mengklaim PID harus berubah saat klik. Handler `terminated-click` membuktikan startup membaca `getInitialMessage`. Tidak memakai force-stop. Screenshot kondisi terminated diambil saat recent apps kosong, sebelum pengiriman terakhir.

Ketiga halaman tujuan sama karena tujuan payload sama. Panel notifikasi sendiri tidak membedakan state; screenshot kondisi dan log handler melengkapinya. Gambar home menunjukkan ikhtisar, sementara gambar home_bottom menunjukkan hasil demo 401. Arti, pasangan bukti, serta batas setiap screenshot dicatat di [screenshot_audit.md](screenshot_audit.md).

## Pengiriman Firebase Console

Pengguna melengkapi pengujian manual dengan tiga screenshot: `fcm-console-campaign.png` menunjukkan project `campus-notify-244107020049`, campaign `Jadwal kuliah berubah`, target Android, dan status **Completed**; `fcm-console-test.png` menunjukkan notifikasi berjudul sama beserta isi `Kelas Mobile pindah ke Ruang A2 jam 13.00`; `fcm-console-detail.png` menunjukkan halaman **Pengumuman #3** dan tujuan `/pengumuman/3` setelah klik. Ini melengkapi langkah pengiriman Console pada Praktikum 2. Timestamp tampilan Console adalah 4 Oktober 2026, 11:18:35 PM; zona waktu tampilan tidak diverifikasi. Pengujian ini didokumentasikan dari bukti pengguna, tanpa menambahkan log CLI atau messageId yang tidak direkam.

## Token Lifecycle

- `getToken` mengirim POST `/devices` ke adapter demo: log awal 19:50:56 WIB.
- Rotasi: `deleteToken` diikuti `getToken`, 19:55:30–19:55:31 WIB. Listener **onTokenRefresh** melakukan POST `/devices` dan log mencatat `token berubah=true`. Prefix dapat tetap sama walau bagian token lainnya berubah; perbandingan menggunakan token lengkap di memori, tanpa mencetaknya.
- Clear data menggunakan `adb shell pm clear id.ac.polinema.campus_notify`, lalu membuka ulang aplikasi, login, dan memberikan permission kembali.
- Prefix awal `dz7GghtnQgGr…`; prefix setelah clear data `d-Z-rWIhQje7…`. Registrasi baru tercatat 19:58:22 WIB.
- Backend `/devices` **simulasi di memori**, bukan backend persisten. Bukti ini membuktikan callback melakukan request, bukan penyimpanan user/perangkat pada server produksi.

## Topic dan Payload

- Unsubscribe dan subscribe menghasilkan log sukses serta perubahan switch.
- Data-only dikirim pada foreground melalui opsi `--data-only`. `onMessage` menerima pesan dan mencatat rute tanpa menampilkan notification. Bukti: `praktikum3_data_only_foreground.png`.
- Pengujian payload gabungan memenuhi matriks tiga state. Data-only tambahan diuji pada foreground; background/terminated data-only belum diklaim teruji.

## Analisis dan Unit Test

`flutter analyze`: No issues found. Hasil terminal aktual disimpan di `flutter_analyze.txt`.

Hasil terminal aktual unit test disimpan di `flutter_test.txt`. Empat test pada `test/auth_push_test.dart` lulus: parsing rute, ID payload, provider sesi/logout, dan refresh Dio. Firebase tidak diinisialisasi oleh test. Ini sesuai bagian testing codelab; tidak ada widget test template yang tersisa.

## Artefak

- `fcm_events.txt`: log aktual yang difilter hanya event `[FCM]`, tanpa token penuh.
- `fcm_sends.jsonl`: respons pengiriman yang direkam oleh script; hanya status, timestamp, jenis, dan nama pesan.
- `screenshots/`: 28 gambar mencakup login, validasi, refresh, permission, lifecycle token, tiga app state, topic, data-only, halaman utama, hasil terminal analyze dan test, serta pengiriman Firebase Console.
- `screenshot_audit.md`: arti dan batas bukti seluruh 28 screenshot.
- Firebase client configuration tetap lokal. Tidak ada service-account key di repo.

## Batas Verifikasi

Android teruji; iOS/APNs belum dikonfigurasi. Auth dan backend API default mock sesuai codelab. Tidak ada klaim JWT produksi atau penyimpanan token perangkat di backend nyata. Matriks tiga state menggunakan Firebase HTTP v1 dengan akun lokal pengguna tanpa menyalin kredensial. Pengiriman Console tambahan dibuktikan melalui screenshot pengguna; konfigurasi custom data dan log penerima untuk campaign tersebut tidak direkam terpisah.
