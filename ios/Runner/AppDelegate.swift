import Flutter
import UIKit
import SafariServices
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    Messaging.messaging().delegate = self
    Messaging.messaging().isAutoInitEnabled = true
    UserDefaults.standard.set("launch_started", forKey: "mleysoft_aidat_apns_status")
    UserDefaults.standard.set("", forKey: "mleysoft_aidat_apns_error")

    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized ||
         settings.authorizationStatus == .provisional ||
         settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async {
          UserDefaults.standard.set("register_requested", forKey: "mleysoft_aidat_apns_status")
          application.registerForRemoteNotifications()
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized ||
         settings.authorizationStatus == .provisional ||
         settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async {
          UserDefaults.standard.set("register_requested_active", forKey: "mleysoft_aidat_apns_status")
          application.registerForRemoteNotifications()
        }
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set("success", forKey: "mleysoft_aidat_apns_status")
    UserDefaults.standard.set("", forKey: "mleysoft_aidat_apns_error")
    UserDefaults.standard.set(tokenHex, forKey: "mleysoft_aidat_apns_token")

    Messaging.messaging().apnsToken = deviceToken
    Messaging.messaging().token { token, error in
      if let token, !token.isEmpty {
        UserDefaults.standard.set(token, forKey: "mleysoft_aidat_fcm_token")
      }
      UserDefaults.standard.set(error?.localizedDescription ?? "", forKey: "mleysoft_aidat_fcm_error")
    }

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    UserDefaults.standard.set("failed", forKey: "mleysoft_aidat_apns_status")
    UserDefaults.standard.set(error.localizedDescription, forKey: "mleysoft_aidat_apns_error")
    UserDefaults.standard.set("", forKey: "mleysoft_aidat_apns_token")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    UserDefaults.standard.set(fcmToken ?? "", forKey: "mleysoft_aidat_fcm_token")
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.mleysoft.aidat/legal_browser",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "open",
            let args = call.arguments as? [String: Any],
            let raw = args["url"] as? String,
            let url = URL(string: raw) else {
        result(FlutterMethodNotImplemented)
        return
      }

      DispatchQueue.main.async {
        guard let scene = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Yasal sayfa açılamadı.", details: nil))
          return
        }

        var presenter = root
        while let presented = presenter.presentedViewController {
          presenter = presented
        }
        let safari = SFSafariViewController(url: url)
        safari.modalPresentationStyle = .pageSheet
        if let sheet = safari.sheetPresentationController {
          sheet.detents = [.large()]
          sheet.prefersGrabberVisible = true
        }
        presenter.present(safari, animated: true)
        result(true)
      }
    }
  }
}
