import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

public final class MleySoftNativeBridgePlugin: NSObject, FlutterPlugin, MessagingDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance=MleySoftNativeBridgePlugin(); let messenger=registrar.messenger()
    registrar.addApplicationDelegate(instance); Messaging.messaging().delegate=instance
    let channel=FlutterMethodChannel(name:"com.mleysoft.aidat/notifications",binaryMessenger:messenger)
    registrar.addMethodCallDelegate(instance,channel:channel)
  }
  public func application(_ application:UIApplication,didRegisterForRemoteNotificationsWithDeviceToken deviceToken:Data) {
    let hex=deviceToken.map{String(format:"%02x",$0)}.joined(); let d=UserDefaults.standard
    d.set("success",forKey:"mleysoft_aidat_apns_status"); d.set(hex,forKey:"mleysoft_aidat_apns_token")
    Messaging.messaging().apnsToken=deviceToken
    Messaging.messaging().token { token,error in if let token=token,!token.isEmpty{d.set(token,forKey:"mleysoft_aidat_fcm_token")}; d.set(error?.localizedDescription ?? "",forKey:"mleysoft_aidat_fcm_error") }
  }
  public func application(_ application:UIApplication,didFailToRegisterForRemoteNotificationsWithError error:Error){let d=UserDefaults.standard;d.set("failed",forKey:"mleysoft_aidat_apns_status");d.set(error.localizedDescription,forKey:"mleysoft_aidat_apns_error")}
  public func messaging(_ messaging:Messaging,didReceiveRegistrationToken fcmToken:String?){if let f=fcmToken,!f.isEmpty{UserDefaults.standard.set(f,forKey:"mleysoft_aidat_fcm_token")}}
  public func handle(_ call:FlutterMethodCall,result:@escaping FlutterResult){
    switch call.method {
    case "requestPermission","requestNotificationPermission":
      UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.badge,.sound]){granted,error in DispatchQueue.main.async{if let error=error{result(FlutterError(code:"NOTIFICATION_PERMISSION_ERROR",message:error.localizedDescription,details:nil))}else{if granted{UIApplication.shared.registerForRemoteNotifications()};result(granted)}}}
    case "registerForRemoteNotifications": DispatchQueue.main.async{UIApplication.shared.registerForRemoteNotifications();result(true)}
    case "getAPNsRegistrationStatus": let d=UserDefaults.standard;DispatchQueue.main.async{result(["status":d.string(forKey:"mleysoft_aidat_apns_status") ?? "unknown","error":d.string(forKey:"mleysoft_aidat_apns_error") ?? "","apns_token":d.string(forKey:"mleysoft_aidat_apns_token") ?? "","fcm_token":d.string(forKey:"mleysoft_aidat_fcm_token") ?? "","fcm_error":d.string(forKey:"mleysoft_aidat_fcm_error") ?? "","system_registered":UIApplication.shared.isRegisteredForRemoteNotifications ? "1":"0"])}
    case "getNativePushTokens": DispatchQueue.main.async{UIApplication.shared.registerForRemoteNotifications();Messaging.messaging().token{fcm,error in if let error=error{result(FlutterError(code:"FCM_TOKEN_ERROR",message:error.localizedDescription,details:nil));return};let d=UserDefaults.standard;let fa=Messaging.messaging().apnsToken?.map{String(format:"%02x",$0)}.joined() ?? "";let apns=fa.isEmpty ? (d.string(forKey:"mleysoft_aidat_apns_token") ?? "") : fa;result(["fcm_token":fcm ?? (d.string(forKey:"mleysoft_aidat_fcm_token") ?? ""),"apns_token":apns])}}
    default: result(FlutterMethodNotImplemented)
    }
  }
}
