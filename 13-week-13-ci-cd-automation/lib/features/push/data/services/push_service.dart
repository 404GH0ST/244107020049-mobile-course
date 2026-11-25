import 'dart:async';

import '../../domain/repositories/push_repository.dart';
import '../../domain/repositories/device_repository.dart';

import '../../../../firebase_options.dart';
import '../../../../core/format.dart';
import '../../../../core/failures.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Isolate terpisah: jangan akses BuildContext, router, atau Riverpod.
  // Notification payload ditampilkan Android; jangan buat banner kedua.
  debugPrint(
    '[FCM] background id=${message.messageId} route=${routeFromMessage(message.data)}',
  );
}

class PushService extends ChangeNotifier implements PushRepository {
  PushService({
    required this.firebaseReady,
    required this.devices,
    required this.mockBackend,
  });
  @override
  final bool firebaseReady;
  final DeviceRepository devices;
  final bool mockBackend;
  final _local = FlutterLocalNotificationsPlugin();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  void Function(String)? _go;
  Future<void>? _starting;
  Future<void>? _enabling;
  String? _token;
  bool _signedIn = false;
  @override
  bool subscribed = false;
  @override
  bool busy = false;
  @override
  String permission = 'Belum diminta';
  @override
  String registration = 'Belum terdaftar';
  @override
  String status = 'Menyiapkan layanan';
  @override
  final List<String> events = [];
  @override
  String get maskedToken => _token == null
      ? 'Belum tersedia'
      : '${_token!.substring(0, _token!.length < 12 ? _token!.length : 12)}…';
  static const topic = 'pengumuman-kampus';
  static const channel = AndroidNotificationChannel(
    'pengumuman',
    'Pengumuman Kampus',
    description: 'Informasi perkuliahan',
    importance: Importance.high,
  );

  void _event(String text) {
    events.insert(0, text);
    if (events.length > 12) events.removeLast();
    debugPrint('[FCM] $text');
    notifyListeners();
  }

  @override
  Future<void> start(void Function(String) go) {
    _go = go;
    return _starting ??= _start();
  }

  Future<void> _start() async {
    if (!firebaseReady) {
      status = 'Firebase belum dikonfigurasi. Tambahkan google-services.json lalu build ulang.';
      notifyListeners();
      return;
    }
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = routeFromMessage({'route': response.payload});
          _event('foreground-click route=$route');
          _go?.call(route);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
      // iOS: hanya local notification yang present saat foreground, cegah duplikasi.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((message) {
          unawaited(_foreground(message));
        }),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          final route = routeFromMessage(message.data);
          _event('background-click id=${message.messageId} route=$route');
          _go?.call(route);
        }),
      );
      _subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen(
          (token) {
            unawaited(_registerToken(token, source: 'onTokenRefresh'));
          },
          onError: (Object _) {
            _event(
              const NetworkFailure(
                'Token refresh gagal; coba aktifkan notifikasi kembali.',
              ).message,
            );
          },
        ),
      );
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        final route = routeFromMessage(initial.data);
        _event('terminated-click id=${initial.messageId} route=$route');
        _go?.call(route);
      }
      final localInitial = await _local.getNotificationAppLaunchDetails();
      if (localInitial?.didNotificationLaunchApp == true) {
        final route = routeFromMessage({
          'route': localInitial?.notificationResponse?.payload,
        });
        _event('local-terminated-click route=$route');
        _go?.call(route);
      }
      status = 'Firebase siap';
      notifyListeners();
    } catch (_) {
      status = const LocalFailure(
        'Inisialisasi notifikasi gagal. Periksa konfigurasi Firebase.',
      ).message;
      notifyListeners();
    }
  }

  Future<void> _foreground(RemoteMessage message) async {
    _event(
      'foreground id=${message.messageId} route=${routeFromMessage(message.data)}',
    );
    // Data-only dicatat tanpa banner; gabungan notification + data ditampilkan lokal.
    if (message.notification == null) return;
    try {
      await _local.show(
        id: message.messageId.hashCode & 0x7fffffff,
        title: message.notification!.title ?? 'Pengumuman',
        body: message.notification!.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pengumuman',
            'Pengumuman Kampus',
            icon: 'ic_notification',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
        payload: routeFromMessage(message.data),
      );
    } catch (_) {
      _event(const LocalFailure('Gagal menampilkan banner lokal.').message);
    }
  }

  @override
  Future<void> syncSession(bool signedIn) async {
    _signedIn = signedIn;
    if (signedIn) {
      await enable();
    } else {
      if (firebaseReady && subscribed) {
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        } catch (_) {
          _event(
            const NetworkFailure(
              'Unsubscribe gagal; coba kembali saat jaringan tersedia.',
            ).message,
          );
        }
      }
      subscribed = false;
      registration = 'Sesi belum login';
      notifyListeners();
    }
  }

  @override
  Future<void> enable() =>
      _enabling ??= _enable().whenComplete(() => _enabling = null);
  Future<void> _enable() async {
    await _starting;
    if (!firebaseReady || !_signedIn) return;
    busy = true;
    notifyListeners();
    try {
      // Android 13+: POST_NOTIFICATIONS. iOS: alert/badge/sound dan APNs diperlukan.
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      permission = settings.authorizationStatus.name;
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        status = 'Izin notifikasi belum diberikan';
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        status = 'Token belum tersedia. Periksa Google Play Services.';
        return;
      }
      await _registerToken(token, source: 'getToken');
      if (_signedIn) await setTopic(true);
      status = 'Notifikasi aktif';
    } catch (_) {
      status = const NetworkFailure(
        'Gagal mengaktifkan notifikasi. Periksa koneksi dan konfigurasi Firebase.',
      ).message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _registerToken(String token, {required String source}) async {
    _token = token;
    if (!_signedIn) {
      registration = 'Menunggu login';
      notifyListeners();
      return;
    }
    try {
      final result = await devices.register(
        token: token,
        platform: defaultTargetPlatform.name,
      );
      if (result.failure != null) {
        registration = result.failure!.message;
        _event('$source → registrasi perangkat gagal');
        return;
      }
      registration = mockBackend
          ? 'POST /devices diterima • backend simulasi'
          : 'POST /devices diterima backend';
      _event(
        '$source → POST /devices berhasil${mockBackend ? ' (simulasi)' : ''}',
      );
    } catch (_) {
      registration = const NetworkFailure('POST /devices gagal • coba lagi')
          .message;
      _event('$source → registrasi perangkat gagal');
    }
  }

  // Kontrol diagnostik praktikum untuk membuktikan listener token refresh.
  @override
  Future<void> rotateToken() async {
    if (!firebaseReady || !_signedIn || busy) return;
    busy = true;
    notifyListeners();
    final previous = _token;
    try {
      await FirebaseMessaging.instance.deleteToken();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        status = 'Token baru belum tersedia';
        return;
      }
      await _registerToken(token, source: 'getToken setelah deleteToken');
      await setTopic(true);
      _event('Rotasi FCM: token berubah=${previous != token}');
    } catch (_) {
      status = const NetworkFailure('Rotasi token gagal. Silakan coba lagi.')
          .message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> setTopic(bool enabled) async {
    if (!firebaseReady || !_signedIn) return;
    try {
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
      subscribed = enabled;
      _event('${enabled ? 'subscribe' : 'unsubscribe'} topic=$topic');
    } catch (_) {
      _event(const NetworkFailure('Perubahan langganan topik gagal.').message);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
