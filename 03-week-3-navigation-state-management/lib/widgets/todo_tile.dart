import 'package:flutter/material.dart';
import '../models/todo.dart';

/// Widget reusable untuk menampilkan satu baris tugas (ToDo item).
///
/// Memisahkan komponen ini dari TodoPage memudahkan pengujian terisolasi
/// dan membuat metode build pada TodoPage jauh lebih ringkas dan mudah dipelihara.
class TodoTile extends StatelessWidget {
  final Todo todo;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = todo.done;

    return Card(
      elevation: isDone ? 0 : 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDone
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      color: isDone
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Semantics(
          label: isDone ? 'Tandai belum selesai' : 'Tandai selesai',
          child: Checkbox(
            value: isDone,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: onToggle,
          ),
        ),
        title: Text(
          todo.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone
                ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                : theme.colorScheme.onSurface,
            fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: todo.description.isNotEmpty
            ? Text(
                todo.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDone
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Lihat detail ${todo.title}',
              child: IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Detail',
                onPressed: onTap,
              ),
            ),
            Semantics(
              label: 'Hapus ${todo.title}',
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Hapus tugas',
                onPressed: onDelete,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
