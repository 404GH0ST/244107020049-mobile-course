import 'package:dio/dio.dart';

import '../../core/failures.dart';

Failure mapDataFailure(Object error) {
  if (error is Failure) return error;
  if (error is! DioException) {
    return const LocalFailure('Terjadi kesalahan. Silakan coba lagi.');
  }
  if (error.response?.statusCode == 401) {
    return const SessionFailure('Sesi berakhir. Silakan login kembali.');
  }
  return NetworkFailure(switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'Koneksi terlalu lama. Silakan coba lagi.',
    DioExceptionType.connectionError => 'Tidak terhubung ke jaringan.',
    DioExceptionType.cancel => 'Permintaan dibatalkan.',
    _ => 'Gagal memuat data. Silakan coba lagi.',
  });
}
