import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/announcements/presentation/providers/announcement_providers.dart';
import '../../providers.dart' show useMockApi;
import '../../../features/push/presentation/providers/push_provider.dart';
import '../../../routes.dart';
import '../../../core/failures.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(sessionDemoProvider);
    final announcements = ref.watch(announcementsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Pengumuman', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Informasi perkuliahan dan notifikasi kampus.'),
          const SizedBox(height: 20),
          announcements.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Column(
              children: [
                Text(failureMessage(error)),
                TextButton(
                  onPressed: () => ref.invalidate(announcementsProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
            data: (items) => items.isEmpty
                ? const Text('Belum ada pengumuman.')
                : Column(
                    children: [
                      for (final item in items)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.campaign_outlined),
                            title: Text(item.title),
                            subtitle: Text(item.subtitle),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                context.go(AppRoutes.announcement(item.id)),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: ref.watch(pushServiceProvider),
            builder: (context, _) {
              final push = ref.read(pushServiceProvider);
              return Card(
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
                          Text(
                            event,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          Text('Keamanan sesi', style: Theme.of(context).textTheme.titleLarge),
          const Text('Access dan refresh token disimpan di secure storage.'),
          if (useMockApi) ...[
            const SizedBox(height: 12),
            const Text('Backend API simulasi • bukan server kampus'),
            FilledButton.tonal(
              onPressed: demo.busy
                  ? null
                  : () => ref.read(sessionDemoProvider.notifier).run(false),
              child: const Text('Simulasikan 401 → refresh → retry'),
            ),
            OutlinedButton(
              onPressed: demo.busy
                  ? null
                  : () => ref.read(sessionDemoProvider.notifier).run(true),
              child: const Text('Simulasikan refresh gagal → logout'),
            ),
            Text(demo.message),
          ],
        ],
      ),
    );
  }
}
