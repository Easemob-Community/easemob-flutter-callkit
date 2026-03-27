Pod::Spec.new do |s|
  s.name             = 'easemob_flutter_callkit'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for EaseMob CallKit'
  s.description      = <<-DESC
A Flutter plugin for EaseMob CallKit, wrapping native Android and iOS SDKs.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'EaseCallUIKit'
  s.dependency 'ChatClient'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
