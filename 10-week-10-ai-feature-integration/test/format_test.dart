import 'package:campus_notify/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tanggal murni mencakup padding dan hari kabisat', () {
    expect(formatDate(DateTime(2026, 10, 1)), '01/10/2026');
    expect(formatDate(DateTime(2024, 2, 29)), '29/02/2024');
  });

  test(
    'payload kosong, tipe salah, dan rute luar aplikasi kembali ke home',
    () {
      for (final route in [
        null,
        3,
        '',
        ' ',
        'https://evil.test',
        '//evil.test',
        '/pengumuman/../3',
        '/login',
        '/pengumuman/3?x=1',
      ]) {
        expect(routeFromMessage({'route': route}), '/');
      }
      expect(routeFromMessage({}), '/');
    },
  );

  test('parser menerima rute pengumuman dengan atau tanpa slash awal', () {
    expect(
      routeFromMessage({'route': 'pengumuman/abc_3'}),
      '/pengumuman/abc_3',
    );
    expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
  });
}
