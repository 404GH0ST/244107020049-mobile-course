import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';
import '../widgets/search_empty_state.dart';

final isSyncingProvider = NotifierProvider<IsSyncingNotifier, bool>(
  IsSyncingNotifier.new,
);

class IsSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSyncing(bool val) => state = val;
}

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final dirtyCountAsync = ref.watch(dirtyCountProvider);
    final isOffline = ref.watch(forceOfflineProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          IconButton(
            tooltip: 'Lihat Cache-First Posts',
            icon: const Icon(Icons.dynamic_feed_outlined),
            onPressed: () => context.push('/posts'),
          ),
          IconButton(
            tooltip: 'Sinkronisasi Sekarang',
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Badge(
                    isLabelVisible: (dirtyCountAsync.value ?? 0) > 0,
                    label: Text('${dirtyCountAsync.value ?? 0}'),
                    child: const Icon(Icons.cloud_upload_outlined),
                  ),
            onPressed: isSyncing ? null : () => _performSync(context, ref),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isOffline) _buildOfflineBanner(context, ref),
          const _SearchNotesHeader(),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Memuat catatan lokal dari SQLite...'),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat catatan:\n$error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(notesProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  if (searchQuery.trim().isNotEmpty) {
                    return SearchEmptyState(
                      query: searchQuery,
                      onClear: () =>
                          ref.read(searchQueryProvider.notifier).clear(),
                    );
                  }
                  return _buildEmptyNotesState(context);
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(notesProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteTile(
                        note: note,
                        onTap: () {
                          if (note.id != null) {
                            context.push('/note/${note.id}');
                          }
                        },
                        onDelete: () => _confirmDelete(context, ref, note),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mode Pesawat / Offline Aktif. Catatan tetap dapat dibaca dan ditambah lokal ke SQLite.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              ref.read(forceOfflineProvider.notifier).setOffline(false);
            },
            child: const Text('Online-kan'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan lokal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Catatan disimpan secara persisten di SQLite perangkat Anda. Tekan tombol + untuk membuat catatan baru.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    final isOffline = ref.read(forceOfflineProvider);

    ref.read(isSyncingProvider.notifier).setSyncing(true);
    try {
      final syncedCount = await syncNotes(repo, forceOffline: isOffline);
      ref.invalidate(notesProvider);
      ref.invalidate(dirtyCountProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              syncedCount > 0
                  ? 'Berhasil menyinkronkan $syncedCount catatan ke server (dirty = 0).'
                  : 'Semua catatan sudah tersinkronisasi (antrean kosong).',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: Text('$e')),
        );
      }
    } finally {
      ref.read(isSyncingProvider.notifier).setSyncing(false);
    }
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Catatan Offline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul Catatan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              ref
                  .read(notesProvider.notifier)
                  .addNote(title: title, body: bodyController.text.trim());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Note note) {
    if (note.id == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Apakah Anda yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(note.id!);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _SearchNotesHeader extends ConsumerStatefulWidget {
  const _SearchNotesHeader();

  @override
  ConsumerState<_SearchNotesHeader> createState() => _SearchNotesHeaderState();
}

class _SearchNotesHeaderState extends ConsumerState<_SearchNotesHeader> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    if (_controller.text != query) {
      _controller.text = query;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        key: const Key('search_notes_field'),
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  key: const Key('search_clear_button'),
                  icon: const Icon(Icons.clear),
                  tooltip: 'Bersihkan pencarian',
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          ref.read(searchQueryProvider.notifier).setQuery(val);
        },
      ),
    );
  }
}
