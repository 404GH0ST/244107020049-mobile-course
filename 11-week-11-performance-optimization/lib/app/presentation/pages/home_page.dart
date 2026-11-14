import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failures.dart';
import '../../../features/announcements/domain/entities/announcement.dart';
import '../../../features/announcements/presentation/providers/announcement_providers.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/push/presentation/providers/push_provider.dart';
import '../../../routes.dart';
import '../../providers.dart' show useMockApi;

/// Kerangka halaman tidak mengamati provider apa pun sehingga tidak ikut
/// rebuild ketika feed, status push, atau demo sesi berubah.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openChat(BuildContext context) => context.push(AppRoutes.chat);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Campus Notify'),
      actions: [
        IconButton(
          tooltip: 'Tanya Asisten AI',
          onPressed: () => _openChat(context),
          icon: const Icon(Icons.smart_toy_outlined),
        ),
        IconButton(
          tooltip: 'Keluar',
          onPressed: () => ref.read(authStateProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openChat(context),
      icon: const Icon(Icons.smart_toy_outlined),
      label: const Text('Tanya Asisten AI'),
    ),
    body: const _HomeFeed(),
  );
}

class _HomeFeed extends ConsumerStatefulWidget {
  const _HomeFeed();
  @override
  ConsumerState<_HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends ConsumerState<_HomeFeed> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Muat halaman berikutnya ±200 px sebelum akhir list.
  void _onScroll() {
    if (_scroll.position.extentAfter < 200) {
      ref.read(announcementFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(announcementFeedProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(announcementFeedProvider.future),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _AssistantCard(),
                SizedBox(height: 16),
                _PushStatusCard(),
                SizedBox(height: 16),
                _SessionSecuritySection(),
                SizedBox(height: 24),
                _FeedHeader(),
                SizedBox(height: 12),
              ]),
            ),
          ),
          ...switch (feed) {
            AsyncValue(:final value?) => _items(value),
            AsyncValue(:final error?) => [
              SliverToBoxAdapter(
                child: _RetryMessage(
                  message: failureMessage(error),
                  onRetry: () => ref.invalidate(announcementFeedProvider),
                ),
              ),
            ],
            _ => const [
              SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
    );
  }

  List<Widget> _items(AnnouncementFeed value) => [
    if (value.items.isEmpty)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Belum ada pengumuman.'),
        ),
      )
    else
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Lazy: hanya item yang terlihat yang di-build dan di-paint.
        sliver: SliverList.builder(
          itemCount: value.items.length,
          itemBuilder: (_, index) => AnnouncementTile(item: value.items[index]),
        ),
      ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: value.loadingMore
              ? const CircularProgressIndicator()
              : value.loadMoreError != null
              ? _RetryMessage(
                  message: value.loadMoreError!,
                  onRetry: ref.read(announcementFeedProvider.notifier).loadMore,
                )
              : value.hasMore
              ? const SizedBox.shrink()
              : const Text('Semua pengumuman sudah dimuat.'),
        ),
      ),
    ),
  ];
}

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({super.key, required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.campaign_outlined),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      trailing: const Icon(Icons.chevron_right),
      // push menjaga HomePage, posisi scroll, dan halaman yang sudah dimuat.
      onTap: () => context.push(AppRoutes.announcement(item.id)),
    ),
  );
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(message),
      TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
    ],
  );
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard();

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer
        .withValues(alpha: 0.35),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
      title: const Text('Asisten AI Kampus Pintar'),
      subtitle: const Text(
        'Panduan kampus, OCR, deskripsi gambar, dan transkripsi suara',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.chat),
    ),
  );
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Pengumuman', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('Informasi perkuliahan dan notifikasi kampus.'),
    ],
  );
}

/// Hanya kartu ini yang rebuild saat status FCM berubah.
class _PushStatusCard extends ConsumerWidget {
  const _PushStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushServiceProvider);
    return ListenableBuilder(
      listenable: push,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifikasi Firebase',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(push.status),
              Text('Izin: ${push.permission}'),
              Text('Token FCM: ${push.maskedToken}'),
              Text(push.registration),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pengumuman kampus'),
                subtitle: const Text('Topik broadcast'),
                value: push.subscribed,
                onChanged: push.firebaseReady && !push.busy
                    ? push.setTopic
                    : null,
              ),
              OutlinedButton(
                onPressed: push.firebaseReady && !push.busy
                    ? push.enable
                    : null,
                child: Text(
                  push.busy
                      ? 'Memproses…'
                      : 'Aktifkan / daftar ulang notifikasi',
                ),
              ),
              TextButton.icon(
                onPressed: push.firebaseReady && !push.busy
                    ? push.rotateToken
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Uji perubahan token FCM'),
              ),
              if (push.events.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Log lifecycle (tanpa token penuh)'),
                for (final event in push.events.take(5))
                  Text(event, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSecuritySection extends StatelessWidget {
  const _SessionSecuritySection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Keamanan sesi', style: Theme.of(context).textTheme.titleLarge),
      const Text('Access dan refresh token disimpan di secure storage.'),
      if (useMockApi) ...[
        const SizedBox(height: 12),
        const Text('Backend API simulasi • bukan server kampus'),
        const _SessionDemoControls(),
      ],
    ],
  );
}

/// `select`: tombol hanya rebuild saat `busy` berubah, teks hanya saat
/// `message` berubah.
class _SessionDemoControls extends ConsumerWidget {
  const _SessionDemoControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(sessionDemoProvider.select((s) => s.busy));
    final demo = ref.read(sessionDemoProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.tonal(
          onPressed: busy ? null : () => demo.run(false),
          child: const Text('Simulasikan 401 → refresh → retry'),
        ),
        OutlinedButton(
          onPressed: busy ? null : () => demo.run(true),
          child: const Text('Simulasikan refresh gagal → logout'),
        ),
        Consumer(
          builder: (_, ref, _) =>
              Text(ref.watch(sessionDemoProvider.select((s) => s.message))),
        ),
      ],
    );
  }
}
