import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/detail_page.dart';
import '../pages/stats_page.dart';
import '../pages/todo_page.dart';
import '../widgets/scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Konfigurasi GoRouter dengan navigasi deklaratif berbasis ShellRoute
/// dan rute detail dengan path parameter.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ShellRoute untuk halaman dengan NavigationBar bawah (Tugas & Statistik)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'todos',
          builder: (context, state) => const TodoPage(),
        ),
        GoRoute(
          path: '/stats',
          name: 'stats',
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),
    // Rute detail mandiri yang ditumpuk di atas shell (menggunakan _rootNavigatorKey)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/detail/:id',
      name: 'detail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DetailPage(id: id);
      },
    ),
  ],
);
