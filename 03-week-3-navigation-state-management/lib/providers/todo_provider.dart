import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';

/// Notifier untuk mengelola daftar tugas (TodoList) secara immutable.
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    return [
      Todo(
        id: '1',
        title: 'Mempelajari Declarative UI Flutter',
        description: 'Materi praktikum layout responsif minggu 2',
        done: true,
      ),
      Todo(
        id: '2',
        title: 'Konfigurasi GoRouter & Deep Linking',
        description: 'Menerapkan rute deklaratif dan parameter path',
        done: true,
      ),
      Todo(
        id: '3',
        title: 'Implementasi Riverpod State Management',
        description: 'Memisahkan state dari UI menggunakan NotifierProvider',
        done: false,
      ),
      Todo(
        id: '4',
        title: 'Menangani AsyncValue (Loading, Error, Data)',
        description: 'Simulasi fetch asynchronous pada halaman statistik',
        done: false,
      ),
    ];
  }

  /// Menambah tugas baru ke daftar tanpa memutasi state secara langsung.
  void add(String title, {String description = ''}) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      done: false,
    );
    state = [...state, newTodo];
  }

  /// Membalik status selesai (done) dari item tertentu.
  void toggle(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
    ];
  }

  /// Menghapus tugas dari daftar berdasarkan ID.
  void remove(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }

  /// Mengosongkan daftar tugas (berguna untuk testing skenario empty state).
  void clear() {
    state = const [];
  }
}

/// Provider global untuk daftar tugas.
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

/// Notifier untuk filter aktif (Semua, Aktif, Selesai).
class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  void setFilter(TodoFilter filter) {
    state = filter;
  }
}

/// Provider global untuk status filter yang dipilih pengguna.
final todoFilterProvider =
    NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

/// Provider turunan (derived provider) yang menyaring tugas berdasarkan todoFilterProvider.
final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  switch (filter) {
    case TodoFilter.active:
      return todos.where((todo) => !todo.done).toList();
    case TodoFilter.completed:
      return todos.where((todo) => todo.done).toList();
    case TodoFilter.all:
      return todos;
  }
});
