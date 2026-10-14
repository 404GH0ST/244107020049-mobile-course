import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Pengumuman #$id'),
      leading: IconButton(
        onPressed: () => context.go(AppRoutes.home),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Chip(label: Text('Konten contoh praktikum')),
        const SizedBox(height: 24),
        Text(
          id == '3' ? 'Jadwal kuliah berubah' : 'Informasi kampus',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Text(
          'Kelas Mobile pindah ke Ruang A2 jam 13.00. Silakan menyesuaikan jadwal perkuliahan.',
        ),
        const SizedBox(height: 24),
        Text('Tujuan deep link: ${AppRoutes.announcement(id)}'),
      ],
    ),
  );
}
