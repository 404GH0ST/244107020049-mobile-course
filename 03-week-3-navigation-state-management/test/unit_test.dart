import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  group('StatsNotifier (AI Challenge) Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      StatsNotifier.forceErrorMode = false;
    });

    tearDown(() {
      container.dispose();
      StatsNotifier.forceErrorMode = null;
    });

    test('StatsNotifier berhasil memuat data statistik sukses (AsyncData)', () async {
      StatsNotifier.forceErrorMode = false;

      // Ambil future dari statsProvider dan tunggu hingga selesai
      final future = container.read(statsProvider.future);
      final items = await future;

      expect(items, isNotEmpty);
      expect(items.length, greaterThanOrEqualTo(3));
      expect(items.any((item) => item.label == 'Total Tugas'), isTrue);
      expect(items.any((item) => item.label == 'Tugas Selesai'), isTrue);
      expect(items.any((item) => item.label == 'Tugas Belum Selesai'), isTrue);
    });

    test('StatsNotifier menangkap error ketika request gagal (AsyncError)', () async {
      StatsNotifier.forceErrorMode = true;

      // Pantau provider menggunakan listener
      container.listen(statsProvider, (prev, next) {});

      // Tunggu hingga delay simulasi fetch selesai
      await Future.delayed(const Duration(seconds: 3));

      final asyncState = container.read(statsProvider);
      expect(asyncState.hasError, isTrue);
      expect(asyncState.error.toString(), contains('Gagal memuat data statistik'));
    });
  });
}
