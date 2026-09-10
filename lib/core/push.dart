import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackground(RemoteMessage message) async {
  try { await Firebase.initializeApp(); } catch (_) {}
}

class PushService {
  static bool _ready = false;
  static bool _permissionAsked = false;
  static const _native = MethodChannel('com.mleysoft.aidat/notifications');

  static Future<void> requestSystemPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    if (Platform.isAndroid) {
      try { await _native.invokeMethod('requestPermission'); } catch (_) {}
    }
  }

  static Future<void> init({bool registerToken = true}) async {
    // Android 13+ izin penceresi Firebase yapılandırmasından bağımsız olarak ilk açılışta gösterilir.
    await requestSystemPermission();
    try {
      if (!_ready) {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(firebaseBackground);
        _ready = true;
      }
    } catch (_) {
      return;
    }
    // iOS izin penceresi APNs/FCM başlatıldıktan sonra Firebase Messaging üzerinden istenir.
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true, provisional: false);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    }
    if (registerToken) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await register(token);
        FirebaseMessaging.instance.onTokenRefresh.listen(register);
      } catch (_) {}
    }
  }

  /// Oturum açıldıktan sonra mevcut FCM tokenını API ile eşitler.
  /// Firebase henüz hazır değilse init() güvenli biçimde başlatır.
  static Future<void> syncToken() async {
    await init(registerToken: true);
  }

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
