import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/login_validation.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('validateEmail', () {
    test('menerima email kampus dan mengabaikan spasi di tepi', () {
      // Arrange
      const inputs = ['demo@kampus.test', '  mhs@polinema.ac.id  '];
      // Act & Assert
      for (final input in inputs) {
        expect(validateEmail(input), isNull, reason: input);
      }
    });

    test('menolak input kosong, null, dan whitespace saja', () {
      expect(validateEmail(''), 'Email wajib diisi');
      expect(validateEmail(null), 'Email wajib diisi');
      expect(validateEmail('   '), 'Email wajib diisi');
    });

    test('menolak format yang hanya mengandung @', () {
      // Regresi: validator lama cukup memeriksa contains('@').
      const invalid = [
        '@',
        'demo@',
        '@kampus.test',
        'demo@kampus',
        'de mo@kampus.test',
        'a@@b.c',
      ];
      for (final input in invalid) {
        expect(
          validateEmail(input),
          'Masukkan email yang valid',
          reason: input,
        );
      }
    });
  });

  group('validatePassword', () {
    test('menerima tepat 6 karakter (batas bawah)', () {
      expect(validatePassword('123456'), isNull);
    });

    test('menolak 5 karakter (tepat di bawah batas)', () {
      expect(validatePassword('12345'), 'Minimal 6 karakter');
    });

    test('menolak kosong dan whitespace saja walau panjangnya cukup', () {
      expect(validatePassword(''), 'Kata sandi wajib diisi');
      expect(validatePassword(null), 'Kata sandi wajib diisi');
      expect(validatePassword('      '), 'Kata sandi wajib diisi');
    });
  });

  group('Login memakai aturan yang sama dengan form', () {
    test('email setengah jadi tidak pernah sampai ke repository', () async {
      final repo = FakeAuthRepository();
      final result = await Login(repo).call(email: 'demo@', password: '123456');
      expect(result.failure, isA<ValidationFailure>());
      expect(repo.loginCalls, 0);
    });

    test('kata sandi 6 spasi ditolak sebelum request', () async {
      final repo = FakeAuthRepository();
      final result = await Login(repo)
          .call(email: 'demo@kampus.test', password: '      ');
      expect(result.failure, isA<ValidationFailure>());
      expect(repo.loginCalls, 0);
    });
  });
}
