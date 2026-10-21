# Checklist review tengah semester

## Praktikum 1 — audit Git dan branching

Project pribadi tetap **Campus Notify akhir Minggu 7**, bukan project Flutter baru.
Fitur kolaborasi menggunakan repository kelompok **LinkGuard**, sesuai dua tautan
pengumpulan yang diminta. Kedua jalur dibedakan agar bukti tidak tercampur.

Perintah audit: `git log --oneline -15`, `git branch -a`, dan `git status`.
Bukti pribadi tersimpan pada `evidence/campus-history.txt`, `campus-branches.txt`,
dan `campus-status.txt`.

| Temuan | Tindak lanjut |
| --- | --- |
| Portfolio hanya memiliki remote main; commit Minggu 7 berada di main | Membuat develop dari origin/main dan branch docs/week-8-mid-project-review, tanpa menulis ulang riwayat yang sudah dipublikasikan |
| PBL memakai feat/* → main; develop belum tersedia | Sempat membuat develop pada basis e9bb183; target akhir feature/onboarding-visuals → main sesuai koreksi pemilik |
| PBL memiliki file PDF/output lokal yang tidak terkait | Menggunakan worktree terpisah; file asli tidak dihapus, di-stage, atau di-commit |
| Ada branch lama fitur anggota lain | Hanya dicatat; usia author commit bukan bukti usia branch. Tidak menghapus branch milik anggota lain |
| Baseline 15 pesan terakhir portfolio sudah Conventional Commits | Tidak mengarang tiga pesan buruk; simulasi di bawah menggunakan tiga pesan nyata yang masih dapat diperjelas |

### Simulasi perbaikan 3 pesan commit

Simulasi saja: tidak melakukan rebase/amend/force-push pada main.

| Commit dan pesan sebelum | Usulan sesudah | Alasan |
| --- | --- | --- |
| 6d1b4f7 chore(week-7): snapshot Campus Notify before clean architecture | chore(week-7): preserve Week 6 baseline for architecture comparison | Tujuan snapshot dan asalnya lebih jelas |
| 07af03f refactor(week-7): wire Riverpod DI and isolate presentation from SDKs (Praktikum 3) | refactor(week-7): inject repositories and isolate SDK access from presentation | Menyatakan perubahan kode, bukan nomor aktivitas praktikum |
| 351ee41 docs(week-7): record APK checks, emulator comparisons, and FCM lifecycle evidence | docs(week-7): document Android build and three FCM lifecycle checks | Menyebut jenis bukti dan tiga kondisi yang diuji |

## Praktikum 2 — issue, PR, dan review sejawat

Issue kelompok: [#12](https://github.com/Zuhdiaja/PBL-MOBILE/issues/12).
PR fitur: [#13](https://github.com/Zuhdiaja/PBL-MOBILE/pull/13).
Basis awal branch: develop pada e9bb183, identik dengan main ketika dibuat.
**Target PR akhir: main**, sesuai arahan pemilik dan alur repository kelompok.
Model develop pada codelab tetap menjadi bahan pembelajaran, bukan kewajiban
mengubah kebijakan integrasi tim.

Checklist review manusia dan tindak lanjut aktual:

Sesuai arahan pemilik, cukup **minimal satu review sejawat** pada PR.
Jumlah temuan atau komentar tidak dipatok; reviewer menilai perubahan secara
bermakna dan hanya melaporkan masalah yang benar-benar ditemukan.

- Catatan: review tidak menyebut reviewer checkout/menjalankan tes; hal tersebut tidak diklaim.
- [x] Minimal satu review sejawat diterima: oninonins memberikan Approve pada head PR.
- [x] Author menindaklanjuti permintaan verifikasi: analyzer bersih, 185 tes lulus ulang, CI hijau, dan alur login terkonfirmasi.
- [x] Tidak ada Request changes; keputusan reviewer sudah Approve sehingga re-review tidak diperlukan.
- [ ] Merge setelah approval; issue ditutup otomatis dan branch dihapus setelah merge.

Format komentar: **observasi → dampak → usulan konkret**.
Contoh bahan diskusi, bukan komentar yang sudah dikirim:
“Back pada langkah 2 harus menjaga state indikator; bila keduanya berbeda,
pengguna menerima konteks salah. Uji dengan Back Android dan periksa label halaman.”

**Status:** [review manusia oleh oninonins](https://github.com/Zuhdiaja/PBL-MOBILE/pull/13#pullrequestreview-5601735553) sudah **APPROVED**.
Masukan sudah diverifikasi; PR belum di-merge. [Rincian tindak lanjut](peer-review.md).
Entri Copilot yang gagal karena kuota tidak dihitung sebagai review sejawat.

## Praktikum 3 — pemeriksaan mesin dan kesiapan

| Pemeriksaan | Hasil | Bukti |
| --- | --- | --- |
| Campus Notify: formatter lib/test | 44 file, 0 berubah | evidence/campus-format.txt |
| Campus Notify: analyzer | Bersih | evidence/campus-analyze.txt |
| Campus Notify: tes | 22 lulus | evidence/campus-test.txt |
| LinkGuard: formatter lib/test | 140 file, 0 berubah | evidence/linkguard-format.txt |
| LinkGuard: analyzer | Bersih | evidence/linkguard-analyze.txt |
| LinkGuard: tes | 185 lulus | evidence/linkguard-test.txt |
| LinkGuard: regresi kode basis | 2 gagal sesuai reproduksi, lalu lulus di kode baru | evidence/onboarding-regressions-before.txt |
| Flutter CI | Berhasil: formatter, analyze, test; target main dan develop | evidence/github-actions.txt |
| Emulator Pixel 10 | Navigasi, Back, geser, login, tema gelap, 320 dp + teks 130% berhasil | emulator-verification.md |

### Tiga pemeriksaan sterilitas Minggu 7

Dijalankan lagi pada kode aktual Campus Notify, bukan disalin sebagai hasil lama:

```sh
rg 'Dio\(|http\.|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode' lib/features/*/presentation lib/app/presentation
rg "(?:import|export) ['\"]package:" lib/features/*/domain lib/core
rg 'DateFormat|jsonDecode|\.toIso8601String|Repository\(|Dio\(BaseOptions' lib/features/*/presentation lib/app/presentation
```

Hasil setiap pencarian: **0 kecocokan**, exit 1 adalah normal untuk `rg` tanpa hasil.
Arah dependency, entity, dan DI tetap seperti akhir Minggu 7.

### Ukuran PR dan pemisahan kerja

Sasaran modul ialah <300 baris. PR ini **melampaui batas tersebut**, terutama karena
menghapus implementasi ilustrasi/kartu lama (408 baris) dan mengganti tes yang
mengikat detail dekorasi lama. Ini dicatat sebagai penyimpangan yang perlu disepakati
reviewer, bukan ditandai patuh secara otomatis.

Kerja dibagi menjadi commit implementasi, tes, dan CI, tanpa menambah fitur lain.
Mengubah menjadi PR aset saja lalu PR UI yang rusak sementara dihindari.
Jika reviewer meminta split, pisahkan infrastruktur CI sebagai PR pendahuluan dan
pertahankan UI + tes sebagai unit perilaku yang bisa dijalankan.

## Definisi selesai

- [x] Implementasi satu fitur, issue dan PR terhubung; target main sesuai arahan pemilik.
- [x] Audit pribadi Minggu 7 dan bukti mesin dijalankan ulang.
- [x] Review AI, dua bukti benar, dan satu saran ditolak dengan alasan.
- [x] Laporan disusun di folder 08-week-8-mid-project-review/.
- [x] APK debug ARM64, pemeriksaan emulator, dan screenshot asli selesai.
- [x] Minimal satu review sejawat, tindak lanjut, dan approval manusia.
- [ ] Merge ke main.
- Catatan ukuran: diff >300 baris sudah diungkapkan; review Approve tidak meminta pemecahan.

Project sudah di-review dan di-approve; **definisi selesai kolaborasi Minggu 8
masih menunggu merge ke main**.
