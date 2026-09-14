import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() {
  runApp(
    // ProviderScope wajib membungkus root aplikasi agar seluruh provider dapat diakses
    const ProviderScope(
      child: Week3App(),
    ),
  );
}

/// Root widget aplikasi Minggu 3: Navigation & State Management.
class Week3App extends StatelessWidget {
  const Week3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 - Navigation & State Management',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
    );
  }
}
