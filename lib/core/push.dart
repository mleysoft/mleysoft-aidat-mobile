import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackground(RemoteMessage message) async {
  try { await Firebase.initializeApp(); } catch (_) {}
}

class PushOpen {
  final String route;
  final String? id;
  const PushOpen(this.route, this.id);
  factory PushOpen.fromMessage(RemoteMessage m) =>
      PushOpen((m.data['route'] ?? 'home').toString(), m.data['id']?.toString());
}

class PushService {
  static bool _ready = false;
  static bool _permissionAsked = false;
  static bool _tapHandlersReady = false;
  static const _native = MethodChannel('com.mleysoft.aidat/notifications');
  static final _opens = StreamController<PushOpen>.broadcast();
  static Stream<PushOpen> get opens => _opens.stream;
  static PushOpen? _pendingOpen;

  static Future<void> requestSystemPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    if (Platform.isAndroid) {
      try { await _native.invokeMethod('requestPermission'); } catch (_) {}
    }
  }

  static Future<void> _setupTapHandlers() async {
    if (_tapHandlersReady) return;
    _tapHandlersReady = true;
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _opens.add(PushOpen.fromMessage(m)));
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _pendingOpen = PushOpen.fromMessage(initial);
    } catch (_) {}
  }

  static PushOpen? takePendingOpen() {
    final p = _pendingOpen;
    _pendingOpen = null;
    return p;
  }

  static Future<String?> _getTokenSafely() async {
    if (Platform.isIOS) {
      // Firebase iOS SDK 10.4+ requires the APNs token before FCM getToken().
      for (var i = 0; i < 20; i++) {
        try {
          final apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns != null && apns.isNotEmpty) break;
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null || apns.isEmpty) return null;
      } catch (_) { return null; }
    }
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> init({bool registerToken = true}) async {
    await requestSystemPermission();
    try {
      if (!_ready) {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(firebaseBackground);
        _ready = true;
      }
    } catch (_) { return; }

    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true, provisional: false);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
    }

    await _setupTapHandlers();

    if (registerToken) {
      try {
        final token = await _getTokenSafely();
        if (token != null) await register(token);
        FirebaseMessaging.instance.onTokenRefresh.listen(register);
      } catch (_) {}
    }
  }

  static Future<void> syncToken() async => init(registerToken: true);

  static Future<void> register(String token) async {
    try {
      await Api.request('device-token', method: 'POST', body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'device_name': 'MleySoft Native',
      });
    } catch (_) {}
  }
}
