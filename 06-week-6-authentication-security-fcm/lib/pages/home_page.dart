import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _result = 'Belum diuji';
  bool _busy = false;
  Future<void> _demo(bool failRefresh) async {
    setState(() => _busy = true);
    try {
      final store = ref.read(tokenStoreProvider);
      if (failRefresh) {
        await store.save(access: (await store.readAccess())!, refresh: '');
      }
      final result = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(
            '/profile',
            options: Options(extra: {'expireAccess': true}),
          );
      if (mounted) {
        setState(
          () => _result = result.data?['message'] as String? ?? 'Sukses',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _result = 'Sesi berakhir. Silakan login kembali.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('Jadwal kuliah berubah'),
            subtitle: const Text('Contoh pengumuman #3'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/pengumuman/3'),
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
            onPressed: _busy ? null : () => _demo(false),
            child: const Text('Simulasikan 401 → refresh → retry'),
          ),
          OutlinedButton(
            onPressed: _busy ? null : () => _demo(true),
            child: const Text('Simulasikan refresh gagal → logout'),
          ),
          Text(_result),
        ],
      ],
    ),
  );
}
