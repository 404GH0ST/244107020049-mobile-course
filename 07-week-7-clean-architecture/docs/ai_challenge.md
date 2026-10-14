# AI Challenge Minggu 7

Acuan: codelab Clean Architecture, project Campus Notify Minggu 6.

## Prompt

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

## Usulan Awal AI

```text
Usulan AI untuk pengerjaan ulang 14 Oktober 2026

Acuan: source Campus Notify Week 6 pada snapshot 6d1b4f7, bukan project baru.
1. Gunakan features/auth, features/announcements, features/push. Auth dan
   announcements mempunyai domain (entity, interface, use case), data
   (model, source, repository impl), dan presentation (provider, halaman).
2. Login menangani validasi dan penyimpanan sesi; GetAnnouncement memvalidasi
   ID sebelum membaca repository. Fetch daftar, restore, dan logout cukup
   lewat repository karena belum membutuhkan aturan tambahan.
3. Semua implementasi disuntikkan melalui app/providers.dart memakai Riverpod.
   Sinyal session expiry berdiri sendiri agar wiring tidak mengimpor notifier
   auth yang mengimpor wiring itu kembali. Bootstrap dan router dipisahkan.
4. Home adalah layar gabungan di app/presentation, bukan milik salah satu
   fitur. SDK HTTP/Firebase/storage tinggal di data; parsing rute dan format
   tanggal di core/format.dart. Mapping hanya di model.
5. Pertahankan callback FCM dan konten Week 6. Jangan membuat API baru,
   fitur notes, package DI kedua, atau wrapper use case per CRUD satu baris.
6. Uji domain dengan fake repository; verifikasi sukses, failure, validasi,
   dan kegagalan simpan sesi. Periksa UI retry, redirect deep link, interceptor,
   graf import, analyzer, APK, serta screenshot before/after emulator.

Trade-off: feature-first menambah file, tetapi memisahkan kontrak dan SDK.
Composition root boleh mengetahui data; widget hanya memperoleh state/provider.
Push tetap memakai listener Dart dan adapter Flutter agar perubahan lifecycle
terbatas. Pemisahan ke event stream belum diperlukan oleh praktikum ini.
```

## Pemetaan semua file lama

| File Week 6 di `lib/` | Layer/masalah awal | Tujuan final |
| --- | --- | --- |
| `main.dart` | Bootstrap, router, dan lifecycle app satu file | Pecah `main.dart`, `app/router.dart`, `app/campus_app.dart` |
| `routes.dart` | Konstanta dan parsing rute bercampur | Konstanta tetap; parser ke `core/format.dart` |
| `data/api_client.dart` | Data; dipakai langsung Home | `app/data/api_client.dart`, hanya repository yang mengakses HTTP |
| `data/api_errors.dart` | Fungsi pesan exception mentah | `app/data/failure_mapper.dart` + `core/failures.dart` |
| `data/auth_repository.dart` | Entity, kontrak, dan mock dalam satu file | Pecah entity, interface, model, mock source, impl, `Login` |
| `data/mock_campus_adapter.dart` | Adapter HTTP simulasi | `app/data/mock_campus_adapter.dart`; tidak di presentation |
| `data/token_store.dart` | Plugin secure storage | `features/auth/data/sources/token_store.dart` |
| `messaging/push_service.dart` | SDK Firebase, lifecycle, HTTP registrasi | Push data service + interface `PushRepository` dan `DeviceRepository` + impl perangkat |
| `pages/announcement_page.dart` | Widget menyimpan konten pengumuman | Page di announcements presentation; konten ke source → model → entity |
| `pages/home_page.dart` | Widget membaca token, memanggil Dio, parsing response | `app/presentation/pages/home_page.dart`; demo ke auth repo/notifier, daftar ke announcements provider |
| `pages/login_page.dart` | Widget form/login | Auth presentation; hanya membaca state dan memanggil notifier |
| `providers/auth_provider.dart` | DI, state, dan akses storage | Wiring ke `app/providers.dart`; state ke auth presentation; sinyal expiry ke `app/session_expiry.dart` |
| `providers/push_provider.dart` | Wiring implementasi Firebase | Wiring ke app; adapter `PushController` ke push presentation |
| `firebase_options.dart` (lokal) | Konfigurasi client Firebase | Tetap bootstrap/data, diabaikan Git |

Folder lama `data/`, `pages/`, `providers/`, `messaging/` dihapus setelah pemetaan.
Project Android/iOS, app ID, asset, dan dependency mengikuti Week 6. Tidak menjalankan
`flutter create` dan tidak menambah fitur atau package.

## Usulan versus keputusan implementasi

| Usulan/opsi | Keputusan | Alasan teknis |
| --- | --- | --- |
| Feature-first tiga layer | Diterapkan pada auth dan announcements; push juga dipisah | Kontrak fitur dapat diuji tanpa SDK dan widget |
| Repository interface di domain | Diterapkan | Data impl dan fake bergantung pada kontrak domain |
| Entity dan model terpisah | Diterapkan | `AnnouncementModel.fromJson/toEntity` di data; entity hanya nilai bisnis |
| Use case untuk semua CRUD | Tidak dipakai | Wrapper fetch daftar, restore, logout satu baris hanya menambah wiring |
| `Login` dan `GetAnnouncement` | Diterapkan | Validasi/normalisasi serta urutan login→simpan; ID divalidasi sebelum baca data |
| Riverpod untuk DI | Diterapkan tanpa package lain | Sudah dipakai Week 6; repository bisa di-override saat test |
| Home di fitur announcements | Dipilih `app/presentation` | Home menggabungkan auth, announcements, dan push |
| Notifier auth diimpor oleh composition root | Dipisahkan melalui sinyal expiry | Menghindari cycle wiring→notifier→wiring |
| Memecah seluruh callback FCM | Tidak dilakukan | Mempertahankan lifecycle Week 6; cukup pisahkan HTTP registrasi dan adapter UI |
| `Result<T>` berupa record Dart | Diterapkan | Failure eksplisit tanpa dependency functional tambahan |

## Contoh wiring DI yang digunakan

```dart
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(ref.watch(announcementSourceProvider)),
);
final getAnnouncementProvider = Provider(
  (ref) => GetAnnouncement(ref.watch(announcementRepositoryProvider)),
);
```

Wiring implementasi berada di `app/providers.dart`; provider state di presentation
memakai provider kontrak/use case. Ini adalah composition root yang diizinkan
mengetahui implementasi. Data dan domain tidak mengimpor presentation. Pemeriksaan
graf juga memeriksa cycle, bukan hanya nama folder.

## AI Verification Checklist

| Pertanyaan modul | Bukti |
| --- | --- |
| Interface domain, implementasi data? | `features/{auth,announcements}/domain/repositories` dan `data/repositories` |
| Domain bebas Flutter/Dio/SQLite/Firebase? | Tiga grep di bawah; domain/core bebas seluruh import package |
| Use case tidak berlebihan? | Hanya `Login` dan `GetAnnouncement`; alasan di tabel keputusan |
| Entity bebas mapping? | Entity hanya berisi nilai bisnis; mapping di data model |
| DI terpusat; widget tidak membuat repository? | Pemeriksaan import + regex presentation |
| Hasil verifikasi tersimpan? | Prompt, output awal, keputusan, dan tiga grep pada file ini; hasil test dan screenshot pada README |

## Trade-off dan tanggung jawab mahasiswa

Feature-first lebih banyak file dibanding struktur Week 6, tetapi perubahan sumber
data tidak mengharuskan widget diubah. `app/data` berisi integrasi HTTP lintas auth
serta registrasi perangkat; bukan domain bisnis. `core` tetap Dart murni.

Push memakai interface listener Dart agar adapter `ChangeNotifier` hanya di
presentation. Service masih memakai Flutter/SDK pada data, yang diperbolehkan;
domain tidak mengetahuinya. Konten pengumuman tetap lokal dan auth tetap mock.

Dokumen ini adalah hasil bantuan AI. Mahasiswa perlu memeriksa trade-off, menentukan
persetujuan atau revisi sendiri, dan mampu menjelaskan panah dependensi saat demo.
Dokumen ini tidak mengklaim persetujuan pribadi mahasiswa yang belum diberikan.

## Hasil Tiga Grep

Dijalankan pada 14 Oktober 2026 dari folder Minggu 7. Folder lama `lib/pages`
sudah dipindahkan; target pencarian adalah folder presentation yang aktual.

### Presentation: SDK dan parsing mentah

```bash
rg 'Dio\(|http\.|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode' lib/features/*/presentation lib/app/presentation
# nol hasil; exit 1
```

### Domain/core: package framework

```bash
rg "(?:import|export) ['\"]package:" lib/features/*/domain lib/core
# nol hasil; exit 1
```

### Presentation: formatting dan instansiasi

```bash
rg 'DateFormat|jsonDecode|\.toIso8601String|Repository\(|Dio\(BaseOptions' lib/features/*/presentation lib/app/presentation
# nol hasil; exit 1
```

## Pengujian

`flutter analyze --no-pub`: **No issues found**, exit 0.
`flutter test --no-pub --reporter expanded`: **22 test lulus**, exit 0.
Use case diuji memakai fake repository tanpa database, HTTP, atau Firebase.
Test sukses/failure tersedia di
[get_announcement_test.dart](../test/get_announcement_test.dart) dan
[login_test.dart](../test/login_test.dart).

Audit project asal dan struktur target ada di [README Minggu 6](../../06-week-6-authentication-security-fcm/README.md#audit-project-lama-untuk-minggu-7-praktikum-1). Hasil akhir dan screenshot ada di [README Minggu 7](../README.md).
