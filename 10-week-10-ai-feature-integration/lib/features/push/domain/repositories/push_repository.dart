abstract interface class PushRepository {
  bool get firebaseReady;
  bool get subscribed;
  bool get busy;
  String get status;
  String get permission;
  String get maskedToken;
  String get registration;
  List<String> get events;
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  Future<void> start(void Function(String) go);
  Future<void> syncSession(bool signedIn);
  Future<void> enable();
  Future<void> setTopic(bool enabled);
  Future<void> rotateToken();
}
