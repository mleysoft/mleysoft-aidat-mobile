import Flutter
import UIKit
import SafariServices
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    return result
  }


  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    NSLog("MleySoft Aidat APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(name: "com.mleysoft.aidat/legal_browser", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "open", let args = call.arguments as? [String: Any], let raw = args["url"] as? String, let url = URL(string: raw) else { result(FlutterMethodNotImplemented); return }
      DispatchQueue.main.async {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }), let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Yasal sayfa açılamadı.", details: nil)); return }
        var presenter = root
        while let presented = presenter.presentedViewController { presenter = presented }
        let safari = SFSafariViewController(url: url); safari.modalPresentationStyle = .pageSheet
        if let sheet = safari.sheetPresentationController { sheet.detents = [.large()]; sheet.prefersGrabberVisible = true }
        presenter.present(safari, animated: true); result(true)
      }
    }
  }
}
