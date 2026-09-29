import Flutter
import UIKit
import SafariServices
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, MessagingDelegate {
  private var sharedFileChannel: FlutterMethodChannel?
  private var pendingSharedFile: String?
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
    _ = consumeSharedBankStatement()
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

  private func consumeSharedBankStatement() -> Bool {
    let group = UserDefaults(suiteName: "group.com.mleysoft.aidat")
    guard let path = group?.string(forKey: "pending_bank_statement"), !path.isEmpty, FileManager.default.fileExists(atPath: path) else { return false }
    group?.removeObject(forKey: "pending_bank_statement")
    pendingSharedFile = path
    sharedFileChannel?.invokeMethod("sharedFileReceived", arguments: path)
    return true
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    UserDefaults.standard.set(fcmToken ?? "", forKey: "mleysoft_aidat_fcm_token")
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.isFileURL {
      let accessed = url.startAccessingSecurityScopedResource()
      defer { if accessed { url.stopAccessingSecurityScopedResource() } }
      do {
        let ext = url.pathExtension.isEmpty ? "xlsx" : url.pathExtension
        let target = FileManager.default.temporaryDirectory.appendingPathComponent("shared_\(UUID().uuidString).\(ext)")
        if FileManager.default.fileExists(atPath: target.path) { try FileManager.default.removeItem(at: target) }
        try FileManager.default.copyItem(at: url, to: target)
        pendingSharedFile = target.path
        sharedFileChannel?.invokeMethod("sharedFileReceived", arguments: target.path)
        return true
      } catch { return false }
    }
    if url.scheme == "mleysoftaidat" && url.host == "bank-import" {
      _ = consumeSharedBankStatement()
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    sharedFileChannel = FlutterMethodChannel(
      name: "com.mleysoft.aidat/shared_file",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    sharedFileChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "getPendingSharedFile" else { result(FlutterMethodNotImplemented); return }
      _ = self?.consumeSharedBankStatement()
      let path = self?.pendingSharedFile
      self?.pendingSharedFile = nil
      result(path)
    }

    let sharedAuthChannel = FlutterMethodChannel(
      name: "com.mleysoft.aidat/shared_auth",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    sharedAuthChannel.setMethodCallHandler { call, result in
      guard call.method == "setToken",
            let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented); return
      }
      let token = (args["token"] as? String) ?? ""
      let defaults = UserDefaults(suiteName: "group.com.mleysoft.aidat")
      if token.isEmpty { defaults?.removeObject(forKey: "share_api_token") }
      else { defaults?.set(token, forKey: "share_api_token") }
      result(true)
    }

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
