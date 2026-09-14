import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

public final class MleySoftNativeBridgePlugin: NSObject, FlutterPlugin, MessagingDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MleySoftNativeBridgePlugin()
    let messenger = registrar.messenger()

    // Same reliability strategy as the working MleySoft IK application:
    // receive UIApplicationDelegate APNs callbacks even if Runner lifecycle
    // behavior changes in TestFlight/Codemagic.
    registrar.addApplicationDelegate(instance)
    Messaging.messaging().delegate = instance
    UserDefaults.standard.set("plugin_registered", forKey: "mleysoft_aidat_apns_status")

    let channel = FlutterMethodChannel(
      name: "com.mleysoft.aidat/notifications",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak instance] call, result in
      instance?.handle(call, result: result)
    }

    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized ||
         settings.authorizationStatus == .provisional ||
         settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
  }

  public func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
    let defaults = UserDefaults.standard
    defaults.set("success", forKey: "mleysoft_aidat_apns_status")
    defaults.set("", forKey: "mleysoft_aidat_apns_error")
    defaults.set(tokenHex, forKey: "mleysoft_aidat_apns_token")

    Messaging.messaging().apnsToken = deviceToken
    Messaging.messaging().token { token, error in
      if let token, !token.isEmpty {
        defaults.set(token, forKey: "mleysoft_aidat_fcm_token")
      }
      defaults.set(error?.localizedDescription ?? "", forKey: "mleysoft_aidat_fcm_error")
    }
  }

  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let defaults = UserDefaults.standard
    defaults.set("failed", forKey: "mleysoft_aidat_apns_status")
    defaults.set(error.localizedDescription, forKey: "mleysoft_aidat_apns_error")
  }

  public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    let defaults = UserDefaults.standard
    if let fcmToken, !fcmToken.isEmpty {
      defaults.set(fcmToken, forKey: "mleysoft_aidat_fcm_token")
      defaults.set("", forKey: "mleysoft_aidat_fcm_error")
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      requestNotificationPermission(result)

    case "requestNotificationPermission":
      requestNotificationPermission(result)

    case "registerForRemoteNotifications":
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        result(true)
      }

    case "getAPNsRegistrationStatus":
      let defaults = UserDefaults.standard
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let auth: String
        switch settings.authorizationStatus {
        case .notDetermined: auth = "notDetermined"
        case .denied: auth = "denied"
        case .authorized: auth = "authorized"
        case .provisional: auth = "provisional"
        case .ephemeral: auth = "ephemeral"
        @unknown default: auth = "unknown"
        }
        DispatchQueue.main.async {
          result([
            "authorization": auth,
            "status": defaults.string(forKey: "mleysoft_aidat_apns_status") ?? "unknown",
            "error": defaults.string(forKey: "mleysoft_aidat_apns_error") ?? "",
            "apns_token": defaults.string(forKey: "mleysoft_aidat_apns_token") ?? "",
            "fcm_token": defaults.string(forKey: "mleysoft_aidat_fcm_token") ?? "",
            "fcm_error": defaults.string(forKey: "mleysoft_aidat_fcm_error") ?? "",
            "system_registered": UIApplication.shared.isRegisteredForRemoteNotifications ? "1" : "0"
          ])
        }
      }

    case "getNativePushTokens":
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().token { fcmToken, error in
          if let error {
            result(FlutterError(code: "FCM_TOKEN_ERROR", message: error.localizedDescription, details: nil))
            return
          }
          let defaults = UserDefaults.standard
          let firebaseApns = Messaging.messaging().apnsToken?
            .map { String(format: "%02x", $0) }.joined() ?? ""
          let apns = firebaseApns.isEmpty
            ? (defaults.string(forKey: "mleysoft_aidat_apns_token") ?? "")
            : firebaseApns
          if let fcmToken, !fcmToken.isEmpty {
            defaults.set(fcmToken, forKey: "mleysoft_aidat_fcm_token")
          }
          result([
            "fcm_token": fcmToken ?? (defaults.string(forKey: "mleysoft_aidat_fcm_token") ?? ""),
            "apns_token": apns
          ])
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestNotificationPermission(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(code: "NOTIFICATION_PERMISSION_ERROR", message: error.localizedDescription, details: nil))
          return
        }
        if granted {
          UIApplication.shared.registerForRemoteNotifications()
        }
        result(granted)
      }
    }
  }
}
