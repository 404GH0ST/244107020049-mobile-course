import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is! DioException) return 'Terjadi kesalahan. Silakan coba lagi.';
  if (error.response?.statusCode == 401) {
    return 'Sesi berakhir. Silakan login kembali.';
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'Koneksi terlalu lama. Silakan coba lagi.',
    DioExceptionType.connectionError => 'Tidak terhubung ke jaringan.',
    DioExceptionType.cancel => 'Permintaan dibatalkan.',
    _ => 'Gagal memuat data. Silakan coba lagi.',
  };
}
