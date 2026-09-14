import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/todo_provider.dart';

/// Halaman Detail Tugas yang diakses melalui rute GoRouter: `/detail/:id`.
///
/// Mendemonstrasikan passing parameter path, deep linking, dan pembacaan
/// data secara reaktif dari Riverpod provider.
class DetailPage extends ConsumerWidget {
  final String id;

  const DetailPage({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final todo = todos.cast<dynamic>().firstWhere(
          (t) => t.id == id,
          orElse: () => null,
        );

    final theme = Theme.of(context);

    if (todo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Tugas dengan ID $id tidak ditemukan',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Kembali ke Daftar'),
              ),
            ],
          ),
        ),
      );
    }

    final isDone = todo.done as bool;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail: ${todo.title}'),
        actions: [
          IconButton(
            icon: Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? Colors.green : null,
            ),
            tooltip: isDone ? 'Tandai belum selesai' : 'Tandai selesai',
            onPressed: () => ref.read(todoListProvider.notifier).toggle(id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.task_alt : Icons.pending,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Tugas',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            isDone ? 'Selesai (Completed)' : 'Belum Selesai (Active)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Judul Tugas',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              todo.title as String,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Deskripsi',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (todo.description as String).isEmpty
                  ? 'Tidak ada deskripsi tambahan.'
                  : todo.description as String,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tag),
              title: const Text('ID Unik'),
              subtitle: Text(id),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Waktu Dibuat'),
              subtitle: Text((todo.createdAt as DateTime).toLocal().toString().split('.')[0]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Daftar Tugas'),
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
