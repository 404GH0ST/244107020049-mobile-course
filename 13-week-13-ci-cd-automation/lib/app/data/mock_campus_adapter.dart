import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

// Adapter demo di memori, bukan backend kampus yang sudah di-deploy.
class MockCampusAdapter implements HttpClientAdapter {
  int requests = 0;
  int deviceRegistrations = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final access = options.headers['Authorization'] as String? ?? '';
    final retried = options.extra['authRetried'] == true;
    final reject =
        access.isEmpty ||
        options.extra['always401'] == true ||
        (options.extra['expireAccess'] == true && !retried);
    if (reject) return _response(401, {'message': 'Sesi kedaluwarsa'});
    if (options.path == '/devices' && options.method == 'POST') {
      deviceRegistrations++;
      // Token tidak disimpan di log, response, atau SharedPreferences.
      return _response(201, {'registered': true, 'simulation': true});
    }
    return _response(200, {
      'message': retried ? '401 → refresh sekali → retry 200' : 'Request 200',
      'simulation': true,
    });
  }

  ResponseBody _response(int status, Map<String, dynamic> data) =>
      ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
  @override
  void close({bool force = false}) {}
}
