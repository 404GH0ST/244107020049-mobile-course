# Dokumentasi AI Prompt Challenge — Minggu 4

## Identitas Mahasiswa

- Nama: Agus Prasetyo
- NIM: 244107020049
- Kelas: TI-3H
- Program Studi: D4 Teknik Informatika
- Mata Kuliah: Pemrograman Mobile

## 1. Prompt yang Digunakan

Berikut adalah prompt yang diberikan kepada AI Coding Assistant sesuai panduan Codelab Minggu 4:

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id} dari JSONPlaceholder menggunakan Dio + flutter_riverpod. Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError) dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

## 2. Output Awal AI

Berikut adalah keluaran kode awal yang digenerasikan oleh AI:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model data Comment
class Comment {
  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: json['postId'] as int,
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

// Repository untuk memanggil API
class CommentRepository {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await dio.get('/comments', queryParameters: {'postId': postId});
    final list = response.data as List;
    return list.map((e) => Comment.fromJson(e)).toList();
  }
}

// Provider
final commentRepoProvider = Provider((ref) => CommentRepository());

class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  @override
  Future<List<Comment>> build() async {
    return [];
  }

  Future<void> load(int postId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(commentRepoProvider).fetchComments(postId));
  }
}
```

## 3. AI Verification Checklist & Temuan Kritis

Berdasarkan AI Verification Checklist pada modul Codelab, ditemukan beberapa kelemahan arsitektural dan potensi runtime crash pada kode awal AI:

- Apakah UI memanggil Dio secara langsung atau lewat repository?
  - Status: Lolos kriteria dasar, pemanggilan dilakukan via repository. Namun, repository membuat instance Dio baru secara internal (`final Dio dio = Dio(...)`), bukan melalui dependency injection dari `dioProvider`.
- Apakah fromJson aman null, atau masih memakai cast langsung yang bisa crash?
  - Status: Ditemukan Bug Kritis. Pada field numerik, AI menulis `json['postId'] as int` dan `json['id'] as int`. Jika API mengembalikan nilai `null`, `double`, atau field tidak ditemukan, kode akan langsung melempar error fatal `type 'Null' is not a subtype of type 'int'` atau `type 'double' is not a subtype of type 'int'`.
- Apakah semua tipe DioExceptionType dipetakan ke pesan pengguna yang ramah?
  - Status: Belum optimal. Output awal AI tidak menyertakan fungsi pemetaan pesan error yang lengkap untuk `badResponse` (status code 404, 500, 401/403) dan timeout types secara terpusat.
- Apakah baseUrl dan timeout terpusat di satu client?
  - Status: Tidak terpusat. Instance Dio di-instansiasi ulang di dalam `CommentRepository`, melanggar prinsip Single Source of Truth (SSOT). Seharusnya repository menerima instance `Dio` dari luar melalui constructor injection.
- Kualitas pengujian unit test:
  - Status: Test awal hanya menguji happy path sederhana dan tidak menguji skenario edge case seperti seluruh field `null` atau tipe angka desimal.

## 4. Perbaikan dan Keputusan Rekayasa

Perbaikan yang diterapkan pada arsitektur proyek Minggu 4:

- Null-safe Defensive Casting pada Model `Comment`:
  - Mengubah casting angka menjadi `(json['postId'] as num?)?.toInt() ?? 0` dan `(json['id'] as num?)?.toInt() ?? 0`.
  - Memberikan fallback string kosong `as String? ?? ''` untuk `name`, `email`, dan `body`.
  - Menjadikan constructor `const` dan seluruh field berstatus `final` guna menjamin *immutability*.
- Dependency Injection untuk Dio Client:
  - `CommentRepository` menerima `Dio` dari constructor: `CommentRepository(this._dio);`.
  - Menggunakan konfigurasi terpusat dari `api_client.dart` (`createDio()`) yang dikelola oleh `dioProvider`.
- Sentralisasi Pemetaan Error Jaringan:
  - Memanfaatkan fungsi bersama `friendlyErrorMessage` di `lib/data/network_errors.dart` yang menangani `connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, serta kode status HTTP 404, 401/403, dan 500.
- Pengujian Komprehensif:
  - Menambahkan unit test spesifik untuk `Comment.fromJson` dengan missing field dan edge case seluruh data kosong di `test/post_test.dart`.

## 5. Hasil Pengujian Verifikasi

Seluruh pengujian unit test dan validasi linter berhasil dijalankan tanpa error:

- `flutter analyze`: Hasil analisis menunjukkan `No issues found!`.
- `flutter test`: Sebanyak 11 test case (termasuk unit test model Post, Comment, mapping error jaringan, dan mock repository) lulus 100%.
