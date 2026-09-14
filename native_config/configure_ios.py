#!/usr/bin/env python3
from pathlib import Path
import plistlib, shutil, re
root=Path(__file__).resolve().parents[1]
ios=root/'ios'; runner=ios/'Runner'; pbx=ios/'Runner.xcodeproj'/'project.pbxproj'
if not ios.exists() or not runner.exists() or not pbx.exists(): raise SystemExit('ERROR: flutter create iOS platformu olusturmadi')
# icons
src_icons=root/'assets'/'ios_appicon'; dst_icons=runner/'Assets.xcassets'/'AppIcon.appiconset'; dst_icons.mkdir(parents=True,exist_ok=True)
for f in src_icons.glob('*'):
    if f.is_file(): shutil.copy2(f,dst_icons/f.name)
# Firebase plist
fb_src=root/'native_config'/'firebase'/'GoogleService-Info.plist'; fb_dst=runner/'GoogleService-Info.plist'
shutil.copy2(fb_src,fb_dst)
with fb_dst.open('rb') as f: fb=plistlib.load(f)
if fb.get('BUNDLE_ID')!='com.mleysoft.aidat': raise SystemExit('ERROR: Firebase BUNDLE_ID yanlis')
# Info.plist - same strategy as working IK
info_path=runner/'Info.plist'
with info_path.open('rb') as f: info=plistlib.load(f)
info['CFBundleDisplayName']='MleySoft Aidat'; info['CFBundleName']='Runner'
modes=list(info.get('UIBackgroundModes',[]))
for mode in ['fetch','remote-notification']:
    if mode not in modes: modes.append(mode)
info['UIBackgroundModes']=modes
info.pop('FirebaseAppDelegateProxyEnabled',None)
with info_path.open('wb') as f: plistlib.dump(info,f,sort_keys=False)
# pbx
text=pbx.read_text(encoding='utf-8')
text=re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*RunnerTests;','PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.aidat.RunnerTests;',text)
for old in set(re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',text)):
    if 'RunnerTests' not in old:
        text=text.replace(f'PRODUCT_BUNDLE_IDENTIFIER = {old};','PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.aidat;')
text=re.sub(r'PRODUCT_NAME = [^;]+;','PRODUCT_NAME = Runner;',text)
if 'INFOPLIST_KEY_CFBundleDisplayName' in text:
    text=re.sub(r'INFOPLIST_KEY_CFBundleDisplayName = [^;]+;','INFOPLIST_KEY_CFBundleDisplayName = "MleySoft Aidat";',text)
text=re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;','IPHONEOS_DEPLOYMENT_TARGET = 15.0;',text)
pbx.write_text(text,encoding='utf-8')
# entitlement
ent=runner/'Runner.entitlements'
with ent.open('wb') as f: plistlib.dump({'aps-environment':'production'},f,sort_keys=False)
text=pbx.read_text(encoding='utf-8')
text=re.sub(r'\s*CODE_SIGN_ENTITLEMENTS = Runner/[^;]+;','',text)
lines=text.splitlines(); out=[]; bundle='PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.aidat;'
for line in lines:
    out.append(line)
    if bundle in line:
        indent=line[:len(line)-len(line.lstrip())]; out.append(indent+'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;')
text='\n'.join(out)+('\n' if text.endswith('\n') else '')
if 'com.apple.Push =' not in text:
    marker='CreatedOnToolsVersion ='; idx=text.find(marker)
    if idx<0: raise SystemExit('ERROR: TargetAttributes yok')
    end=text.find(';',idx)+1
    cap='\n\t\t\t\t\t\tSystemCapabilities = {\n\t\t\t\t\t\t\tcom.apple.Push = {\n\t\t\t\t\t\t\t\tenabled = 1;\n\t\t\t\t\t\t\t};\n\t\t\t\t\t\t};'
    text=text[:end]+cap+text[end:]
# Firebase resource
fid='F10500000000000000000001'; bid='F10500000000000000000002'
if 'GoogleService-Info.plist in Resources' not in text:
    text=text.replace('/* Begin PBXBuildFile section */',f'/* Begin PBXBuildFile section */\n\t\t{bid} /* GoogleService-Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* GoogleService-Info.plist */; }};',1)
    text=text.replace('/* Begin PBXFileReference section */',f'/* Begin PBXFileReference section */\n\t\t{fid} /* GoogleService-Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "GoogleService-Info.plist"; sourceTree = "<group>"; }};',1)
    ad=next((l for l in text.splitlines() if 'AppDelegate.swift /* AppDelegate.swift */,' in l),None)
    if not ad: raise SystemExit('ERROR: AppDelegate PBXGroup point yok')
    text=text.replace(ad,ad+f'\n\t\t\t\t{fid} /* GoogleService-Info.plist */,',1)
    rl=next((l for l in text.splitlines() if 'LaunchScreen.storyboard in Resources */,' in l),None)
    if not rl: raise SystemExit('ERROR: Resources point yok')
    text=text.replace(rl,rl+f'\n\t\t\t\t{bid} /* GoogleService-Info.plist in Resources */,',1)
pbx.write_text(text,encoding='utf-8')
# xcconfig entitlement
for xc in ['Debug.xcconfig','Release.xcconfig']:
    p=ios/'Flutter'/xc; s=p.read_text(encoding='utf-8'); s='\n'.join(l for l in s.splitlines() if not l.strip().startswith('CODE_SIGN_ENTITLEMENTS'))+'\nCODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements\n'; p.write_text(s,encoding='utf-8')
# AppDelegate adapted from working IK
app=runner/'AppDelegate.swift'
app.write_text('''import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    Messaging.messaging().delegate = self
    Messaging.messaging().isAutoInitEnabled = true
    UserDefaults.standard.set("launch_started", forKey: "mleysoft_aidat_apns_status")
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async { application.registerForRemoteNotifications() }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral {
        DispatchQueue.main.async { application.registerForRemoteNotifications() }
      }
    }
  }
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenHex=deviceToken.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set("success",forKey:"mleysoft_aidat_apns_status")
    Messaging.messaging().apnsToken=deviceToken
    Messaging.messaging().token { token,error in
      if let token=token,!token.isEmpty { UserDefaults.standard.set(token,forKey:"mleysoft_aidat_fcm_token") }
      UserDefaults.standard.set(error?.localizedDescription ?? "",forKey:"mleysoft_aidat_fcm_error")
    }
    super.application(application,didRegisterForRemoteNotificationsWithDeviceToken:deviceToken)
  }
  override func application(_ application:UIApplication,didFailToRegisterForRemoteNotificationsWithError error:Error) {
    UserDefaults.standard.set("failed",forKey:"mleysoft_aidat_apns_status")
    UserDefaults.standard.set(error.localizedDescription,forKey:"mleysoft_aidat_apns_error")
    super.application(application,didFailToRegisterForRemoteNotificationsWithError:error)
  }
  func messaging(_ messaging:Messaging,didReceiveRegistrationToken fcmToken:String?) {
    UserDefaults.standard.set(fcmToken ?? "",forKey:"mleysoft_aidat_fcm_token")
  }
}
''',encoding='utf-8')
# verify
with info_path.open('rb') as f: vi=plistlib.load(f)
if vi.get('CFBundleDisplayName')!='MleySoft Aidat' or vi.get('CFBundleName')!='Runner': raise SystemExit('ERROR: app name config')
verify=pbx.read_text(encoding='utf-8'); bc=verify.count(bundle); ec=verify.count('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;')
if bc<3 or ec<bc: raise SystemExit(f'ERROR entitlement binding {bc}/{ec}')
if 'GoogleService-Info.plist in Resources' not in verify: raise SystemExit('ERROR Firebase resource')
print('AIDAT IOS CONFIG OK')
print('Display Name: MleySoft Aidat')
print('CFBundleName: Runner')
print(f'Bundle configs={bc} entitlement configs={ec}')
