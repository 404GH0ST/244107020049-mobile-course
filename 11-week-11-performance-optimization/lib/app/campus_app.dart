import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/push/presentation/providers/push_provider.dart';
import 'router.dart';

class CampusApp extends ConsumerStatefulWidget {
  const CampusApp({super.key});
  @override
  ConsumerState<CampusApp> createState() => _CampusAppState();
}

class _CampusAppState extends ConsumerState<CampusApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final push = ref.read(pushServiceProvider);
      await push.start(ref.read(routerProvider).go);
      if (mounted) {
        await push.syncSession(ref.read(authStateProvider).value ?? false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (next.hasValue && !next.isLoading) {
        unawaited(
          ref.read(pushServiceProvider).syncSession(next.value ?? false),
        );
      }
    });
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1769aa)),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
