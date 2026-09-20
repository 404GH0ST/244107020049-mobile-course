import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/paged_posts.dart';
import '../data/providers.dart';
import '../widgets/post_tile.dart';

class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() => _PagedPostPageState();
}

class _PagedPostPageState extends ConsumerState<PagedPostPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        ref.read(pagedPostsProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    if (state.error != null && state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Posts Paged')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  friendlyErrorMessage(state.error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(pagedPostsProvider.notifier).loadFirstPage(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty && state.page == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Posts Paged')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Paged'),
        actions: [
          IconButton(
            tooltip: 'Reload Pertama',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(pagedPostsProvider.notifier).loadFirstPage(),
          ),
        ],
      ),
      body: ListView.separated(
        controller: _controller,
        itemCount: state.items.length + 1,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            if (!state.hasMore) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Semua data termuat.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = state.items[index];
          return PostTile(
            post: post,
            onTap: () => context.push('/post/${post.id}'),
          );
        },
      ),
    );
  }
}
