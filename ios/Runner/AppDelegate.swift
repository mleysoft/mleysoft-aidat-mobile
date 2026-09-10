import Flutter
import UIKit
import SafariServices
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.mleysoft.aidat/legal_browser", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak controller] call, result in
        guard call.method == "open", let args = call.arguments as? [String: Any], let raw = args["url"] as? String, let url = URL(string: raw) else { result(FlutterMethodNotImplemented); return }
        let safari = SFSafariViewController(url: url)
        safari.modalPresentationStyle = .pageSheet
        if let sheet = safari.sheetPresentationController { sheet.detents = [.large()]; sheet.prefersGrabberVisible = true }
        controller?.present(safari, animated: true)
        result(true)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
