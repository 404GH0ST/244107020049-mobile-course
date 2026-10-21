# Verifikasi emulator Android

Tanggal: 21 Oktober 2026. Screenshot diambil dari aplikasi yang benar-benar
terpasang dan berjalan, melalui `adb exec-out screencap -p`.

## Lingkungan dan provenance

- AVD: **Pixel_10 / Pixel 10**, serial `emulator-5554`.
- Android **17**, API **37**, arsitektur **ARM64**.
- Resolusi standar **1080 × 2424**, densitas **420 dpi** (sekitar 411 dp lebar).
- APK aplikasi: `com.example.pbl_semester5`, build debug ARM64 dari head `be6a67a`.
- Pembanding dibangun dari basis `e9bb183` pada checkout asli; gambar “sebelum”
  adalah kode basis, bukan gambar yang diambil sebelum seluruh aktivitas sesi.
- Flutter **3.47.7**, Dart **3.13.5**.
- Pengujian layar kecil: override resolusi **840 × 1470**, densitas tetap 420 dpi
  (320 × 560 dp), `font_scale=1.3`.
- Dark mode: `adb shell cmd uimode night yes`; kembali ke `no` setelah pengujian.

Build debug ARM64 berhasil. Build awal membutuhkan penyegaran package config
(`flutter pub get`) dan cache native `.cxx` plugin `jni` yang sudah lama.
Cache build dipindahkan ke lokasi sementara lalu dibangun ulang, tanpa mengubah
source plugin, source aplikasi, lockfile, atau versi dependency. Build pembanding
dan build final dijalankan berurutan untuk menghindari perebutan cache native.
Lihat [log build akhir](evidence/linkguard-build-arm64.txt).

## Skenario yang benar-benar dijalankan

| ID | Langkah | Hasil teramati |
| --- | --- | --- |
| E01 | Install APK final, buka aplikasi | Langkah 1, judul Kenali tautan sebelum dibuka, ilustrasi browser/kaca pembesar besar |
| E02 | Tap Berikutnya | Langkah 2, ilustrasi perisai dan judul Jangan buru-buru. Kenali risikonya. |
| E03 | Tekan KEYCODE_BACK pada langkah 2 | Kembali ke langkah 1; judul dan indikator konsisten |
| E04 | Geser ke kiri dari langkah 1 | Berpindah ke langkah 2 |
| E05 | Berikutnya dari langkah 2 | Langkah 3, ilustrasi ponsel/riwayat dan tombol Mulai sekarang |
| E06 | Mulai sekarang | Halaman login lama, judul Masuk. |
| E07 | Night mode yes, cold launch | Onboarding memakai permukaan gelap dan teks terang; gambar tetap terlihat |
| E08 | 320 dp + teks 130%, gulir konten | Judul/deskripsi bisa dibaca dengan scroll; tombol tetap terjangkau. Konten lebih panjang dari viewport, bukan dipaksa mengecil |
| E09 | Berikutnya → Berikutnya → Mulai sekarang pada E08 | Ketiga langkah tetap bisa dilalui dan berakhir pada login |
| E10 | Kembalikan ukuran/teks/tema, cold launch, Lewati | Halaman login lama tampil |
| E11 | Install basis e9bb183, cold launch | Onboarding lama ditangkap sebagai pembanding |
| E12 | Install kembali APK final, cold launch | Emulator ditinggalkan pada onboarding baru; resolusi, font, dan night mode telah dipulihkan |

Semantics diverifikasi melalui hierarchy UI Android (judul, label tombol, dan
indikator), kemudian screenshot diperiksa secara visual dalam satu contact sheet.
Tidak ditemukan exception layout/asset pada log Flutter selama pemeriksaan.

## Bukti gambar

| File | Isi |
| --- | --- |
| [before-onboarding.png](../screenshots/before-onboarding.png) | Basis lama e9bb183 |
| [onboarding-1.png](../screenshots/onboarding-1.png) | Browser dan kaca pembesar |
| [onboarding-2.png](../screenshots/onboarding-2.png) | Perisai kewaspadaan |
| [onboarding-3.png](../screenshots/onboarding-3.png) | Ponsel dan riwayat |
| [onboarding-dark.png](../screenshots/onboarding-dark.png) | Tema gelap |
| [onboarding-large-text-top.png](../screenshots/onboarding-large-text-top.png) | Posisi awal layar 320 dp dan teks 130%; konten dapat digulir |
| [onboarding-large-text.png](../screenshots/onboarding-large-text.png) | Setelah scroll, teks dan tombol tetap dapat dibaca/dijangkau |
| [login-after-onboarding.png](../screenshots/login-after-onboarding.png) | Tujuan akhir yang sudah ada |

Screenshot ini bukan golden/snapshot test, bukan screenshot browser, dan bukan
ilustrasi hasil generator yang diklaim sebagai aplikasi. Generator hanya dipakai
untuk tiga aset ilustrasi yang kemudian dibundel dan ditampilkan oleh Flutter.

## Mengulang pengujian

```sh
rtk proxy flutter build apk --debug --no-pub --target-platform android-arm64
rtk proxy adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
rtk proxy adb -s emulator-5554 shell am start -W -n com.example.pbl_semester5/.MainActivity
rtk proxy adb -s emulator-5554 exec-out screencap -p > onboarding.png
rtk proxy adb -s emulator-5554 shell cmd uimode night yes
rtk proxy adb -s emulator-5554 shell wm size 840x1470
rtk proxy adb -s emulator-5554 shell settings put system font_scale 1.3
# Uji navigasi dan scroll, lalu pulihkan:
rtk proxy adb -s emulator-5554 shell wm size reset
rtk proxy adb -s emulator-5554 shell settings put system font_scale 1.0
rtk proxy adb -s emulator-5554 shell cmd uimode night no
```

## Batas bukti

Tidak menguji perangkat fisik, iOS, tablet, FCM baru pada Campus Notify, atau
layanan pemeriksaan URL nyata. Emulator membuktikan layout dan alur yang diuji;
bukan pengukuran performa produksi atau hasil riset kegunaan dengan pengguna.
