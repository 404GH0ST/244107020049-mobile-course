import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const kWideBreakpoint = 700.0;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              Semantics(
                label: isDark ? 'Mode gelap aktif' : 'Mode terang aktif',
                child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
              const SizedBox(width: 4),
              Semantics(
                label: 'Toggle tema gelap',
                child: CupertinoSwitch(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= kWideBreakpoint;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProfileHeader(),
                const SizedBox(height: 16),
                _buildCardGrid(context, isWide),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardGrid(BuildContext context, bool isWide) {
    const cards = [
      InfoCard(title: 'Mata Kuliah', value: '8', icon: Icons.menu_book),
      InfoCard(title: 'SKS Semester', value: '19', icon: Icons.assignment),
      InfoCard(title: 'IP Semester Lalu', value: '4.00', icon: Icons.star),
      InfoCard(title: 'IPK', value: '3.92', icon: Icons.school),
      InfoCard(title: 'Semester', value: '5', icon: Icons.calendar_today),
      InfoCard(title: 'Kelas', value: '3H', icon: Icons.group),
    ];

    if (isWide) {
      final rows = <Widget>[];
      for (var i = 0; i < cards.length; i += 2) {
        final second = i + 1 < cards.length ? cards[i + 1] : null;
        rows.add(Row(
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 16),
            Expanded(child: second ?? const SizedBox.shrink()),
          ],
        ));
        if (i + 2 < cards.length) rows.add(const SizedBox(height: 16));
      }
      return Column(children: rows);
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i < cards.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Foto profil mahasiswa',
            child: CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.person, size: 36, color: colorScheme.onPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agus Prasetyo',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIM: 244107020049',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'D4 Teknik Informatika - Semester 5',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$title: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: textTheme.bodyLarge),
              ),
              Text(value, style: textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
