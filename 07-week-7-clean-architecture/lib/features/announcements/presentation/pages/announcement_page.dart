import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../../../../core/failures.dart';
import '../providers/announcement_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text('Pengumuman #$id'),
      leading: IconButton(
        onPressed: () => context.go(AppRoutes.home),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: ref
        .watch(announcementProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failureMessage(error)),
                TextButton(
                  onPressed: () => ref.invalidate(announcementProvider(id)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Chip(label: Text('Konten contoh praktikum')),
              const SizedBox(height: 24),
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(item.body),
              const SizedBox(height: 24),
              Text('Tujuan deep link: ${AppRoutes.announcement(id)}'),
            ],
          ),
        ),
  );
}
