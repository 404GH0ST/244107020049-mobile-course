import 'package:flutter_riverpod/flutter_riverpod.dart';

// Bridge untuk callback interceptor. Tidak mengimpor widget atau notifier auth.
final sessionExpiryProvider = NotifierProvider<SessionExpiryNotifier, int>(
  SessionExpiryNotifier.new,
);

class SessionExpiryNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void expire() => state++;
}
