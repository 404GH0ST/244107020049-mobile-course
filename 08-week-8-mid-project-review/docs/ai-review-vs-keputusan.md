# Review AI dibandingkan keputusan teknis

Tanggal: 21 Oktober 2026. Author: Agus Prasetyo (244107020049, TI-3H).
AI dipakai sebagai reviewer awal, bukan sebagai reviewer sejawat atau pemberi approval.
Keputusan yang direkam di bawah merupakan keputusan implementasi dalam sesi berbantuan AI;
mahasiswa tetap perlu memeriksa, memahami, dan menjelaskannya saat demo.

## Konteks dan prompt

Basis review: `Zuhdiaja/PBL-MOBILE@e9bb183`, khusus onboarding.
LinkGuard memakai feature-first dengan constructor injection; tidak mengasumsikan
Riverpod, GoRouter, SQLite, atau Dio ada pada onboarding.

```text
Review onboarding Flutter ini sebagai senior Flutter developer.
Konteks: feature-first Clean Architecture (presentation → domain ← data).
State onboarding lokal; navigasi lintas fitur diteruskan melalui onComplete.
Fokus kebenaran, arsitektur, dan test. Abaikan style formatter.
Berikan 5 temuan/usulan teratas + level (blocker/saran), alasan,
dan potongan kode perbaikan. Verifikasi setiap temuan sebelum diterapkan.
Bandingkan juga dengan kebutuhan ilustrasi besar dan bahasa Indonesia.
```

## Output awal AI terhadap kode basis

1. **Blocker — label Inggris pada layar sempit.** `_navigationButtons` memilih
   `compact ? 'Next' : 'Berikutnya'`. Pada 320 px, syarat bahasa Indonesia dilanggar.
   Usul: `Text(isLast ? 'Mulai sekarang' : 'Berikutnya')`, tetap bisa membungkus.
2. **Blocker — Back Android tidak mengikuti langkah.** State langkah berubah lewat
   tombol sendiri; tidak ada penanganan pop. Pada langkah 2, Back tidak kembali
   ke langkah 1. Usul `PopScope(canPop: index == 0, onPopInvokedWithResult: ...)`.
3. **Saran — ilustrasi terlalu kecil untuk brief.** Widget lama memakai ikon 72
   dalam lingkaran 150 dan kartu ilustrasi tinggi maksimum 330. Usul ilustrasi
   original besar per langkah, tanpa meniru tampilan aplikasi kripto referensi.
4. **Saran — callback selesai tidak dijaga.** `onComplete` dipanggil langsung dari
   Lewati dan Mulai. Bila parent belum mengganti halaman, tap berulang bisa
   menjalankan aksi penyelesaian lebih dari sekali. Usul guard satu sesi:
   `if (_completed) return; _completed = true; widget.onComplete();`.
5. **Saran — simpan status selesai agar onboarding tidak muncul setiap restart.**
   Usul awal berupa `SharedPreferences.getInstance()` langsung di halaman.
   Ini rekomendasi pengembangan berikutnya, bukan bug yang dibuktikan pada brief.

## Verifikasi dan keputusan

| ID | Bukti | Keputusan dan alasan |
| --- | --- | --- |
| R1 | Tes `regression: compact onboarding uses Indonesian navigation` gagal pada basis: menemukan `Next`, lalu lulus setelah perubahan | Terima. Semua ukuran memakai teks Indonesia; tidak menyembunyikan label utama untuk menghindari overflow |
| R2 | Tes `regression: system Back returns to the previous step` gagal pada basis: judul langkah 1 tidak ditemukan sesudah Back, lalu lulus pada perubahan | Terima. PopScope meneruskan Back normal pada langkah pertama dan kembali satu langkah pada langkah berikutnya |
| R3 | Pemeriksaan kode basis menunjukkan `size: 72`, plat 150, artwork clamp 230–330; screenshot sebelum/sesudah melengkapi bukti | Terima. Tiga aset WebP transparan original dan area gambar 64% viewport konten, clamp 240–440, bukan ikon kecil |
| R4 | Callback lama dipanggil langsung; tes akhir `skip from step 0/1/2 completes once` menekan Lewati dua kali, menghitung tepat 1 callback | Terima guard lokal; tidak mengubah autentikasi atau menyimpan state baru ke perangkat |
| R5 | Pencarian pada halaman membuktikan tidak ada akses storage. `main.dart` memang menyimpan selesai hanya di state sesi | **Tolak bentuk usulan dan tunda fiturnya.** Akses plugin langsung melanggar aturan presentation; persistensi tidak diminta pada pembaruan visual. Bila ditambahkan kelak, gunakan kontrak domain, data adapter, dan composition root |

Dua bukti negatif sebelum perbaikan tersimpan lengkap pada
[evidence/onboarding-regressions-before.txt](evidence/onboarding-regressions-before.txt).
Kegagalan tersebut disengaja untuk menguji efektivitas regresi, bukan hasil akhir.
Seluruh 185 tes akhir lulus pada [evidence/linkguard-test.txt](evidence/linkguard-test.txt).

### Potongan final yang diterima

```dart
return PopScope<void>(
  canPop: _index == 0,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop && _index > 0) _goTo(_index - 1);
  },
  child: Scaffold(/* ... */),
);
```

`_goTo` memilih `jumpToPage` ketika animasi dinonaktifkan atau
`animateToPage` 300 ms; PageController di-dispose oleh pemilik state.
Widget tidak mengimpor data layer dan tidak membuat repository konkret.

## Batas keputusan dan tindak lanjut

- Pernyataan keamanan otomatis tidak ditambahkan. Gambar adalah ilustrasi konsep;
  bukan klasifikasi sebuah URL dan bukan bukti API/kamera sudah terhubung.
- Tema mengikuti `AppPalette`, `linkGuardTheme`, dan font Manrope yang sudah ada.
- Onboarding tetap muncul sesuai perilaku launch gate lama ketika sesi aplikasi dimulai lagi.
- Pembaruan ini tidak mengubah project Campus Notify Minggu 7; audit 22 tesnya
  dijalankan ulang dan dilampirkan secara terpisah.
- Pembaruan: oninonins sudah memberi Approve pada head PR. Masukan verifikasi
  ditindaklanjuti; lihat [review sejawat](peer-review.md). Tidak ada self-approval
  atau klaim merge; PR masih terbuka.

## Referensi API yang diperiksa

Context7 dicoba lebih dahulu, tetapi kuota bulanan habis. Fallback ke dokumentasi resmi:
[PageView](https://api.flutter.dev/flutter/widgets/PageView-class.html) dan
[PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html).
