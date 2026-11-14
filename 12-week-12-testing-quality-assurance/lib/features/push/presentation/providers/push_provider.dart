import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/repositories/push_repository.dart';

final pushServiceProvider = Provider<PushController>((ref) {
  final controller = PushController(ref.watch(pushRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

// Adapter Listenable di presentation, tanpa ketergantungan pada Firebase/Dio.
class PushController extends ChangeNotifier {
  PushController(this._repository) {
    _repository.addListener(notifyListeners);
  }
  final PushRepository _repository;
  bool get firebaseReady => _repository.firebaseReady;
  bool get busy => _repository.busy;
  bool get subscribed => _repository.subscribed;
  String get status => _repository.status;
  String get permission => _repository.permission;
  String get maskedToken => _repository.maskedToken;
  String get registration => _repository.registration;
  List<String> get events => List.unmodifiable(_repository.events);
  Future<void> start(void Function(String) go) => _repository.start(go);
  Future<void> syncSession(bool signedIn) => _repository.syncSession(signedIn);
  Future<void> enable() => _repository.enable();
  Future<void> setTopic(bool enabled) => _repository.setTopic(enabled);
  Future<void> rotateToken() => _repository.rotateToken();
  @override
  void dispose() {
    _repository.removeListener(notifyListeners);
    super.dispose();
  }
}
