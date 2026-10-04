# Kontrak Registrasi Perangkat

Codelab mengizinkan backend registrasi didokumentasikan. Aplikasi default memakai `MockCampusAdapter` dalam memori; respons sukses **bukan bukti backend kampus yang sudah berjalan**. FCM tetap menggunakan layanan Firebase nyata.

## Endpoint

```http
POST /devices
Authorization: Bearer <access-token>
Content-Type: application/json

{"fcm_token": "<registration-token>", "platform": "android"}
```

Backend produksi harus memverifikasi identitas, mengaitkan token dengan user dari sesi terverifikasi, dan melakukan upsert dengan timestamp. Jangan percaya user ID dari payload. Token perangkat dapat berubah, sehingga `getToken` dan setiap `onTokenRefresh` perlu mengirim registrasi terbaru. Respons yang diharapkan: HTTP 200/201 tanpa mengembalikan token penuh.

Untuk memakai backend sungguhan, jalankan dengan `--dart-define=USE_MOCK_API=false --dart-define=CAMPUS_API_URL=https://API_ANDA`. Repository auth juga harus diganti dengan penerbit token sah yang dikenali backend. Mock access token tidak valid untuk backend produksi.

Logout membersihkan token auth dan unsubscribe topik. Pada produksi, tambahkan endpoint pencabutan asosiasi user/perangkat saat logout dan tangani token FCM yang ditolak server (`UNREGISTERED`). Implementasi demo tidak menyediakan backend personal notification.

## Pengiriman Praktikum

`send_notification.cjs` membaca akun Firebase CLI lokal dan meminta access token sementara di memori. Script mengirim payload gabungan ke topik `pengumuman-kampus` melalui FCM HTTP v1. Kredensial tidak ditulis ke repository atau dicetak.

```bash
node docs/send_notification.cjs campus-notify-244107020049
node docs/send_notification.cjs campus-notify-244107020049 --data-only
```

Script memakai modul auth internal Firebase CLI dan telah dicoba dengan versi lokal. Struktur internal tersebut dapat berubah pada versi CLI berikutnya. Jika tidak kompatibel, gunakan Firebase Console dengan custom data `route=/pengumuman/3` dan `id=3`.
