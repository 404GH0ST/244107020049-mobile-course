import 'dart:async';

import 'package:campus_notify/app/providers.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/presentation/pages/login_page.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Login yang menunggu [gate] agar state loading bisa diamati tanpa delay.
class GatedAuthRepository extends FakeAuthRepository {
  final gate = Completer<void>();
  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    await gate.future;
    return super.login(email: email, password: password);
  }
}

const emailField = Key('login-email-field');
const passwordField = Key('login-password-field');
const submitButton = Key('login-submit-button');

Future<ProviderContainer> pumpLogin(
  WidgetTester tester,
  FakeAuthRepository repo,
) async {
  usePhoneScreen(tester);
  final container = ProviderContainer.test(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LoginPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('tampilan awal: dua field, tombol Masuk, tanpa error', (
    tester,
  ) async {
    await pumpLogin(tester, FakeAuthRepository());
    expect(find.byKey(emailField), findsOneWidget);
    expect(find.byKey(passwordField), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(submitButton),
        matching: find.text('Masuk'),
      ),
      findsOneWidget,
    );
    expect(find.text('Masukkan email yang valid'), findsNothing);
  });

  testWidgets('input invalid menampilkan pesan dan tidak memanggil login', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await pumpLogin(tester, repo);
    await tester.enterText(find.byKey(emailField), 'demo@');
    await tester.enterText(find.byKey(passwordField), '123');
    await tester.ensureVisible(find.byKey(submitButton));
    await tester.tap(find.byKey(submitButton));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan email yang valid'), findsOneWidget);
    expect(find.text('Minimal 6 karakter'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('field kosong menampilkan pesan wajib diisi', (tester) async {
    await pumpLogin(tester, FakeAuthRepository());
    await tester.ensureVisible(find.byKey(submitButton));
    await tester.tap(find.byKey(submitButton));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('input valid menampilkan loading lalu sesi tersimpan', (
    tester,
  ) async {
    final repo = GatedAuthRepository();
    final container = await pumpLogin(tester, repo);
    await tester.enterText(find.byKey(emailField), ' demo@kampus.test ');
    await tester.enterText(find.byKey(passwordField), '123456');
    await tester.ensureVisible(find.byKey(submitButton));
    await tester.tap(find.byKey(submitButton));
    await tester.pump();
    expect(find.text('Memuat sesi…'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byKey(submitButton));
    expect(button.onPressed, isNull, reason: 'cegah submit ganda');

    repo.gate.complete();
    await tester.pumpAndSettle();
    expect(container.read(authStateProvider).value, isTrue);
    expect(repo.email, 'demo@kampus.test');
    expect(repo.saved, isNotNull);
  });

  testWidgets('failure repository tampil sebagai pesan, bukan exception', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      loginFailure: const NetworkFailure('Tidak terhubung ke jaringan.'),
    );
    final container = await pumpLogin(tester, repo);
    await tester.enterText(find.byKey(emailField), 'demo@kampus.test');
    await tester.enterText(find.byKey(passwordField), '123456');
    await tester.ensureVisible(find.byKey(submitButton));
    await tester.tap(find.byKey(submitButton));
    await tester.pumpAndSettle();
    expect(find.text('Tidak terhubung ke jaringan.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    final auth = container.read(authStateProvider);
    expect(auth.hasError, isTrue);
    expect(auth.value, isNot(isTrue), reason: 'tidak dianggap login');
    expect(repo.saveCalls, 0);
  });
}
