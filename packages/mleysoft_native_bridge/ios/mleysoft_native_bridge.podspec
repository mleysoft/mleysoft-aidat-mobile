Pod::Spec.new do |s|
  s.name             = 'mleysoft_native_bridge'
  s.version          = '1.0.0'
  s.summary          = 'MleySoft Aidat APNs/Firebase native bridge'
  s.description      = 'Deterministic APNs registration and Firebase Messaging token fallback for MleySoft Aidat.'
  s.homepage         = 'https://mleysoft.com'
  s.license          = { :type => 'Private' }
  s.author           = { 'MleySoft' => 'support@mleysoft.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'FirebaseMessaging'
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'
end
