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
  final String? apartmentId;
  final String? siteId;
  const PushOpen(this.route, this.id, {this.apartmentId,this.siteId});
  factory PushOpen.fromMessage(RemoteMessage m) => PushOpen(
    (m.data['route'] ?? 'home').toString(),
    (m.data['id'] ?? m.data['due_id'])?.toString(),
    apartmentId:m.data['apartment_id']?.toString(),
    siteId:m.data['site_id']?.toString(),
  );
}

class PushService {
  static bool _ready = false;
  static bool _permissionAsked = false;
  static bool _tapHandlersReady = false;
  static bool _tokenRefreshBound = false;
  static bool _loggingOut = false;
  static Future<void>? _retryTask;

  static const _native = MethodChannel('com.mleysoft.aidat/notifications');
  static final _opens = StreamController<PushOpen>.broadcast();
  static Stream<PushOpen> get opens => _opens.stream;
  static PushOpen? _pendingOpen;

  static Future<void> requestSystemPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    try {
      if (Platform.isIOS) {
        await _native.invokeMethod('requestNotificationPermission');
        await _native.invokeMethod('registerForRemoteNotifications');
      } else if (Platform.isAndroid) {
        await _native.invokeMethod('requestPermission');
      }
    } catch (_) {}
  }

  static Future<void> _setupTapHandlers() async {
    if (_tapHandlersReady) return;
    _tapHandlersReady = true;
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      if (!_loggingOut) _opens.add(PushOpen.fromMessage(m));
    });
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

  static Future<bool> _hasAppSession() async {
    final t = await Api.token();
    return t != null && t.isNotEmpty;
  }

  static Future<Map<String,String>?> _tokenSnapshot() async {
    try {
      String apns = '';
      String fcm = '';

      if (Platform.isIOS) {
        // First try FlutterFire exactly as normal.
        try { apns = (await FirebaseMessaging.instance.getAPNSToken()) ?? ''; } catch (_) {}
        try { fcm = (await FirebaseMessaging.instance.getToken()) ?? ''; } catch (_) {}

        // Working MleySoft IK fallback:
        // ask FirebaseMessaging native SDK directly through an iOS Flutter plugin.
        if (apns.isEmpty || fcm.isEmpty) {
          try {
            final native = await _native.invokeMapMethod<String,dynamic>('getNativePushTokens');
            final nativeApns = '${native?['apns_token'] ?? ''}';
            final nativeFcm = '${native?['fcm_token'] ?? ''}';
            if (apns.isEmpty && nativeApns.isNotEmpty) apns = nativeApns;
            if (fcm.isEmpty && nativeFcm.isNotEmpty) fcm = nativeFcm;
          } catch (_) {}
        }

        if (apns.isEmpty || fcm.isEmpty) return null;
      } else {
        fcm = (await FirebaseMessaging.instance.getToken()) ?? '';
        if (fcm.isEmpty) return null;
      }

      final app = Firebase.app();
      return {
        'fcm': fcm,
        'apns': apns,
        'project_id': app.options.projectId,
        'app_id': app.options.appId,
        'sender_id': app.options.messagingSenderId,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String,dynamic>?> nativeStatus() async {
    if (!Platform.isIOS) return null;
    try {
      final v = await _native.invokeMapMethod<String,dynamic>('getAPNsRegistrationStatus');
      return v == null ? null : Map<String,dynamic>.from(v);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _registerWithRetry() async {
    if (_retryTask != null) return _retryTask!;
    final completer = Completer<void>();
    _retryTask = completer.future;

    try {
      // TestFlight cihazlarında APNs token ilk açılışta birkaç saniye gecikebilir.
      // TestFlight ilk açılışında APNs token gecikebilir; 3 dakika sessizce tekrar dene.
      for (var i = 0; i < 90; i++) {
        if (_loggingOut || !await _hasAppSession()) return;
        if (Platform.isIOS && i % 5 == 0) {
          try { await _native.invokeMethod('registerForRemoteNotifications'); } catch (_) {}
        }
        final snapshot = await _tokenSnapshot();
        if (snapshot != null) {
          await register(snapshot);
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } finally {
      _retryTask = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  static Future<void> init({bool registerToken = true}) async {
    await requestSystemPermission();

    try {
      if (!_ready) {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(firebaseBackground);
        await FirebaseMessaging.instance.setAutoInitEnabled(true);
        _ready = true;
      }
    } catch (_) {
      return;
    }

    if (Platform.isIOS) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true, provisional: false);
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
      } catch (_) {}
    }

    await _setupTapHandlers();

    if (!_tokenRefreshBound) {
      _tokenRefreshBound = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
        if (!_loggingOut && await _hasAppSession()) {
          final snapshot = await _tokenSnapshot();
          if (snapshot != null) await register(snapshot);
        }
      });
    }

    if (registerToken && !_loggingOut && await _hasAppSession()) {
      final snapshot = await _tokenSnapshot();
      if (snapshot != null) await register(snapshot);
      unawaited(_registerWithRetry());
    }
  }

  static Future<void> syncToken() async {
    _loggingOut = false;
    await init(registerToken: false);
    if (!await _hasAppSession()) return;
    final snapshot = await _tokenSnapshot();
    if (snapshot != null) await register(snapshot);
    unawaited(_registerWithRetry());
  }

  static Future<void> register(Map<String,String> snapshot) async {
    if (_loggingOut || !await _hasAppSession()) return;
    try {
      await Api.request('device-token', method: 'POST', body: {
        'action': 'register',
        'token': snapshot['fcm'] ?? '',
        'apns_token': snapshot['apns'] ?? '',
        'firebase_project_id': snapshot['project_id'] ?? '',
        'firebase_app_id': snapshot['app_id'] ?? '',
        'firebase_sender_id': snapshot['sender_id'] ?? '',
        'platform': Platform.isIOS ? 'ios' : 'android',
        'device_name': Platform.isIOS ? 'MleySoft Aidat iOS / APNs+FCM' : 'MleySoft Aidat Android / FCM',
      });
    } catch (_) {}
  }

  static Future<void> deactivateForLogout() async {
    _loggingOut = true;
    _pendingOpen = null;

    // First deactivate this exact authenticated device/session on our server.
    try {
      if (await _hasAppSession()) {
        await Api.request('device-token', method: 'POST', body: {'action':'deactivate'});
      }
    } catch (_) {}

    // Then invalidate the Firebase installation token on this phone.
    try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
  }

  static Future<void> disableWhileLoggedOut() async {
    _loggingOut = true;
    _pendingOpen = null;
    try {
      if (_ready) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
