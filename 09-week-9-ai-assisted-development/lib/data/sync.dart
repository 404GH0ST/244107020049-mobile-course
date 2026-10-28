import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'repositories/note_repository.dart';

class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };
}

/// Helper untuk membaca seluruh posts yang tersimpan di SQLite cached_posts
Future<List<Post>> readCachedPosts({
  Future<Database> Function()? openDb,
}) async {
  final db = await (openDb ?? openNotesDb)();
  final rows = await db.query('cached_posts', orderBy: 'id ASC');
  return rows.map((r) {
    final payload = jsonDecode(r['payload'] as String) as Map<String, dynamic>;
    return Post.fromJson(payload);
  }).toList();
}

/// Helper untuk menyimpan posts dari API ke dalam tabel SQLite cached_posts
Future<void> saveCachedPosts(
  List<Post> posts, {
  Future<Database> Function()? openDb,
}) async {
  final db = await (openDb ?? openNotesDb)();
  final batch = db.batch();
  for (final post in posts) {
    batch.insert(
      'cached_posts',
      {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}

/// Provider untuk simulasi mode offline deterministik
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setOffline(bool value) => state = value;
}

/// Dio client provider terpusat
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
});

/// Logika sinkronisasi catatan berstatus kotor (dirty = 1)
/// Menjalankan simulasi upload berurutan dan menandai bersih bila berhasil
Future<int> syncNotes(
  NoteRepository repo, {
  bool forceOffline = false,
}) async {
  if (forceOffline) {
    throw Exception('Gagal sinkronisasi: Perangkat sedang dalam mode offline.');
  }

  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  // Simulasi upload ke server dengan latensi jaringan 1 detik
  await Future.delayed(const Duration(seconds: 1));

  // Berdasarkan aturan Last-Write-Wins (LWW), catatan lokal yang di-upload
  // ditandai bersih (dirty = 0) setelah server merespons sukses
  await repo.markAllSynced();
  return dirtyCount;
}

/// Notifier untuk membaca data posts dengan strategi Cache-First
final cachedPostsProvider =
    AsyncNotifierProvider<CachedPostsNotifier, List<Post>>(
  CachedPostsNotifier.new,
);

class CachedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    return _fetchCacheFirst();
  }

  Future<List<Post>> _fetchCacheFirst() async {
    final cached = await readCachedPosts();
    final isOffline = ref.read(forceOfflineProvider);

    if (isOffline) {
      if (cached.isNotEmpty) {
        return cached;
      }
      throw Exception(
        'Mode offline aktif dan belum ada data cache di SQLite.',
      );
    }

    // Jika ada cache lokal, tampilkan segera (cache-first read)
    // lalu jalankan refresh jaringan di background
    if (cached.isNotEmpty) {
      _refreshInBackground();
      return cached;
    }

    // Jika belum ada cache sama sekali, fetch dari jaringan
    return _fetchFromNetworkAndCache();
  }

  void _refreshInBackground() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<List<dynamic>>('/posts?_limit=10');
      final rawList = response.data ?? [];
      final posts = rawList
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList();
      await saveCachedPosts(posts);
      state = AsyncData(posts);
    } catch (_) {
      // Background failure silently ignored agar tidak mengganggu data cache
    }
  }

  Future<List<Post>> _fetchFromNetworkAndCache() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<List<dynamic>>('/posts?_limit=10');
      final rawList = response.data ?? [];
      final posts = rawList
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList();
      await saveCachedPosts(posts);
      return posts;
    } on DioException catch (e) {
      final cached = await readCachedPosts();
      if (cached.isNotEmpty) {
        return cached;
      }
      throw Exception('Koneksi gagal (${e.message}) dan cache kosong.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final isOffline = ref.read(forceOfflineProvider);
      if (isOffline) {
        final cached = await readCachedPosts();
        if (cached.isNotEmpty) return cached;
        throw Exception('Mode offline aktif dan belum ada cache di SQLite.');
      }
      return _fetchFromNetworkAndCache();
    });
  }
}
