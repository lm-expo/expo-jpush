Pod::Spec.new do |s|
  s.name             = 'JPush'
  s.version          = '5.9.0'
  s.module_name      = 'JPush'
  s.summary          = 'Local JPush binary for expo-jpush'
  s.description      = 'Local JPush XCFramework packaged with expo-jpush.'
  s.homepage         = 'https://www.jiguang.cn/'
  s.license          = { :type => 'Commercial' }
  s.author           = { 'Jiguang' => 'support@jiguang.cn' }
  s.source           = { :http => 'https://example.invalid/local-jpush-5.9.0.zip' }
  s.platform         = :ios, '12.0'
  s.static_framework = true
  s.dependency       'JCore', '5.2.2'
  s.vendored_frameworks = 'jpush-ios-5.9.0.xcframework'
  s.preserve_paths   = 'jpush-ios-5.9.0.xcframework'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
end
