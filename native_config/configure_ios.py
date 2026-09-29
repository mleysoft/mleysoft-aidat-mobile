#!/usr/bin/env python3
from pathlib import Path
import plistlib, shutil
root=Path(__file__).resolve().parents[1]
ios=root/'ios'; runner=ios/'Runner'; share=ios/'AidatShare'; pbx=ios/'Runner.xcodeproj'/'project.pbxproj'
if not ios.exists() or not runner.exists() or not share.exists() or not pbx.exists(): raise SystemExit('ERROR: iOS proje/Share Extension dosyalari eksik')
# Icons
src_icons=root/'assets'/'ios_appicon'; dst_icons=runner/'Assets.xcassets'/'AppIcon.appiconset'; dst_icons.mkdir(parents=True,exist_ok=True)
for f in src_icons.glob('*'):
    if f.is_file(): shutil.copy2(f,dst_icons/f.name)
# Firebase
fb_src=root/'native_config'/'firebase'/'GoogleService-Info.plist'; fb_dst=runner/'GoogleService-Info.plist'
if fb_src.exists(): shutil.copy2(fb_src,fb_dst)
if fb_dst.exists():
    with fb_dst.open('rb') as f: fb=plistlib.load(f)
    if fb.get('BUNDLE_ID')!='com.mleysoft.aidat': raise SystemExit('ERROR: Firebase BUNDLE_ID yanlis')
# Main plist: keep document types / URL schemes already in source.
info_path=runner/'Info.plist'
with info_path.open('rb') as f: info=plistlib.load(f)
info['CFBundleDisplayName']='MS Aidat'; info['CFBundleName']='Runner'
info['NSPhotoLibraryUsageDescription']='Aidat ve site yönetimi işlemlerinde gerekli görselleri seçebilmeniz için fotoğraf arşivinize erişim gereklidir.'
info['CFBundleDevelopmentRegion']='tr'; info['CFBundleLocalizations']=['tr','en']; info['LSHasLocalizedDisplayName']=True
modes=list(info.get('UIBackgroundModes',[]))
for mode in ['fetch','remote-notification']:
    if mode not in modes:modes.append(mode)
info['UIBackgroundModes']=modes
with info_path.open('wb') as f: plistlib.dump(info,f,sort_keys=False)
for lang in ['tr','en']:
    lproj=runner/f'{lang}.lproj'; lproj.mkdir(parents=True,exist_ok=True)
    (lproj/'InfoPlist.strings').write_text('CFBundleDisplayName = "MS Aidat";\nCFBundleName = "MS Aidat";\n',encoding='utf-8')
# Do not regenerate AppDelegate/pbxproj: v170 contains native file sharing + real Share Extension target.
text=pbx.read_text(encoding='utf-8')
required=['com.mleysoft.aidat;','com.mleysoft.aidat.share;','AidatShare.appex','Embed App Extensions','Runner/Runner.entitlements','AidatShare/AidatShare.entitlements']
for x in required:
    if x not in text: raise SystemExit('ERROR: iOS Share Extension config eksik: '+x)
for ent in [runner/'Runner.entitlements',share/'AidatShare.entitlements']:
    with ent.open('rb') as f: e=plistlib.load(f)
    if 'group.com.mleysoft.aidat' not in e.get('com.apple.security.application-groups',[]): raise SystemExit('ERROR: App Group entitlement eksik: '+str(ent))
print('AIDAT IOS CONFIG V170 OK - Share Extension preserved')
