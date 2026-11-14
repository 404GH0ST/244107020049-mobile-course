import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: 'access_token');
  Future<String?> readRefresh() => _storage.read(key: 'refresh_token');
  Future<void> clear() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
