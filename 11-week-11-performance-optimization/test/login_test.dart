import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('Login trim email dan simpan sesi setelah login sukses', () async {
    final repo = FakeAuthRepository();
    final result = await Login(repo)
        .call(email: ' demo@kampus.test ', password: '123456');
    expect(result.value, isTrue);
    expect(result.failure, isNull);
    expect(repo.email, 'demo@kampus.test');
    expect(repo.saved?.access, 'access');
    expect(repo.saveCalls, 1);
  });
  test('Input invalid tidak mengakses repository', () async {
    final repo = FakeAuthRepository();
    final result = await Login(repo).call(email: 'invalid', password: '123');
    expect(result.failure, isA<ValidationFailure>());
    expect(repo.loginCalls, 0);
  });
  test('Failure login tidak menyimpan sesi', () async {
    const failure = NetworkFailure('Tidak terhubung ke jaringan.');
    final repo = FakeAuthRepository(loginFailure: failure);
    final result = await Login(repo)
        .call(email: 'a@b.test', password: '123456');
    expect(result.failure, same(failure));
    expect(repo.saveCalls, 0);
  });
  test('Failure storage tidak dilaporkan sebagai login sukses', () async {
    const failure = LocalFailure('Gagal menyimpan sesi.');
    final result = await Login(FakeAuthRepository(saveFailure: failure))
        .call(email: 'a@b.test', password: '123456');
    expect(result.value, isNull);
    expect(result.failure, same(failure));
  });
}
