# AI Prompt Challenge — Campus Notification App

## Prompt

```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## Output Awal

Snapshot draf awal service yang benar-benar dibuat pada sesi pengerjaan disimpan di [ai_output_initial.txt](ai_output_initial.txt). File ini adalah arsip kode, bukan service tambahan yang dijalankan.

## Perbaikan dan Alasan Teknis

1. String rute dipusatkan di `lib/routes.dart`; parsing payload dipisahkan menjadi fungsi murni. Rute eksternal dan rute yang tidak dikenal kembali ke halaman utama.
2. Error Dio dipetakan di `lib/data/api_errors.dart`. UI tidak menampilkan exception mentah atau request yang mungkin membawa token.
3. Contoh interceptor codelab diberi penanda `authRetried` agar retry 401 tidak menyebabkan loop. Request bersamaan berbagi satu Future refresh.
4. Klik foreground langsung diteruskan ke router melalui callback local notification. Menyimpan `pendingDeepLink` saja tanpa mengonsumsinya ketika aplikasi sudah terbuka tidak cukup.
5. Deep link dipertahankan oleh guard lewat parameter `from`, lalu dipakai kembali setelah login; router tidak dibuat ulang setiap perubahan auth.
6. Local notification hanya dibuat untuk pesan yang memiliki `notification`. Background handler tidak membuat banner kedua karena Android sudah menampilkan notification payload.
7. `getToken` dan `onTokenRefresh` menggunakan method registrasi yang sama. `POST /devices` default diterima adapter demo, bukan backend produksi; batas ini ditampilkan di UI dan laporan.
8. Konfigurasi dari FlutterFire digunakan di main isolate dan background isolate. Tidak ada service-account key di aplikasi.

## Android dan iOS

- Android 13+: permission runtime `POST_NOTIFICATIONS`, channel ber-importance tinggi, dan ikon drawable diperlukan. Emulator yang digunakan mempunyai Google Play Services.
- iOS: memerlukan konfigurasi Firebase iOS, APNs key, dan capability Push Notifications. Permission mencakup alert/badge/sound. Opsi present foreground FCM dimatikan agar hanya local notification yang menampilkan banner.
- Praktikum ini dikonfigurasi dan dijalankan pada Android. iOS belum diuji.
- Background handler berjalan di isolate terpisah: tidak boleh memakai BuildContext, Riverpod, atau router. Navigasi dilakukan setelah klik di main isolate.

## AI Verification Checklist

| Pemeriksaan | Temuan |
| :--- | :--- |
| Handler top-level dan entry point | Ada pada `firebaseMessagingBackgroundHandler` |
| Token refresh dikirim ke endpoint | Listener memanggil `_registerToken`, yang melakukan POST `/devices`; mode default simulasi |
| Foreground local notification | `_foreground` memanggil `FlutterLocalNotificationsPlugin.show` |
| Klik tiga state | Lihat matriks dan bukti aktual di README serta `verification.md` |
| Tidak log token penuh | UI hanya menampilkan prefix 12 karakter; log hanya sumber event, status, ID pesan, dan rute |
| Keputusan akhir | Pertahankan mock auth sesuai modul, gunakan FCM sungguhan pada emulator; pisahkan bukti FCM dari backend simulasi |
