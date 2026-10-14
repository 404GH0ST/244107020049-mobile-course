import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../../../app/data/failure_mapper.dart';
import '../../domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  const DeviceRepositoryImpl(this._dio);
  final Dio _dio;
  @override
  Future<Result<void>> register({
    required String token,
    required String platform,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/devices',
        data: {'fcm_token': token, 'platform': platform},
      );
      return (value: null, failure: null);
    } catch (error) {
      return (value: null, failure: mapDataFailure(error));
    }
  }
}
