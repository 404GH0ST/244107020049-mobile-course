import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

/// Halaman utama Daftar Tugas ToDo berbasis Riverpod.
///
/// Menggunakan `filteredTodoListProvider` untuk menampilkan daftar tugas sesuai filter aktif,
/// dan memanfaatkan komponen modular `TodoTile`.
class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca daftar tugas yang sudah difilter
    final todos = ref.watch(filteredTodoListProvider);
    final allTodos = ref.watch(todoListProvider);
    final currentFilter = ref.watch(todoFilterProvider);
    final theme = Theme.of(context);

    final completedCount = allTodos.where((t) => t.done).length;
    final totalCount = allTodos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas (ToDo)'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Ringkasan Status
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progres Mingguan',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '$completedCount dari $totalCount tugas selesai',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  totalCount == 0
                      ? '0%'
                      : '${((completedCount / totalCount) * 100).round()}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Filter Segmented Buttons (Refactoring Challenge 2: derived filter provider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<TodoFilter>(
              segments: const [
                ButtonSegment<TodoFilter>(
                  value: TodoFilter.all,
                  label: Text('Semua'),
                  icon: Icon(Icons.list_alt),
                ),
                ButtonSegment<TodoFilter>(
                  value: TodoFilter.active,
                  label: Text('Aktif'),
                  icon: Icon(Icons.pending_outlined),
                ),
                ButtonSegment<TodoFilter>(
                  value: TodoFilter.completed,
                  label: Text('Selesai'),
                  icon: Icon(Icons.check_circle_outlined),
                ),
              ],
              selected: {currentFilter},
              onSelectionChanged: (newSelection) {
                ref
                    .read(todoFilterProvider.notifier)
                    .setFilter(newSelection.first);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Daftar Tugas atau Tampilan Kosong (Empty State)
          Expanded(
            child: todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada tugas pada kategori ini',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: todos.length,
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return TodoTile(
                        todo: todo,
                        onToggle: (_) =>
                            ref.read(todoListProvider.notifier).toggle(todo.id),
                        onDelete: () =>
                            ref.read(todoListProvider.notifier).remove(todo.id),
                        onTap: () => context.push('/detail/${todo.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tugas Baru'),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Tugas Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas',
                hintText: 'Contoh: Kerjakan PR Minggu 3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Detail atau catatan tugas...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                ref.read(todoListProvider.notifier).add(
                      title,
                      description: descController.text.trim(),
                    );
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
