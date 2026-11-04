import '../../../../core/failures.dart';

abstract interface class DeviceRepository {
  Future<Result<void>> register({
    required String token,
    required String platform,
  });
}
