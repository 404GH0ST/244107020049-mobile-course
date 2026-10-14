import 'package:campus_notify/app/providers.dart';
import 'package:campus_notify/app/router.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('deep link ditahan login lalu kembali ke pengumuman tujuan', (
    tester,
  ) async {
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    await container.read(authStateProvider.future);
    final router = container.read(routerProvider);
    router.go('/pengumuman/3');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masuk'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['from'],
      '/pengumuman/3',
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'demo@kampus.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/pengumuman/3');
    expect(find.text('Jadwal kuliah berubah'), findsOneWidget);
    await container.read(authStateProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Jadwal kuliah berubah'), findsNothing);
  });
}
