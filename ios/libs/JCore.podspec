Pod::Spec.new do |s|
  s.name             = 'JCore'
  s.version          = '5.2.2'
  s.module_name      = 'JCore'
  s.summary          = 'Local JCore binary for expo-jpush'
  s.description      = 'Local JCore XCFramework packaged with expo-jpush.'
  s.homepage         = 'https://www.jiguang.cn/'
  s.license          = { :type => 'Commercial' }
  s.author           = { 'Jiguang' => 'support@jiguang.cn' }
  s.source           = { :http => 'https://example.invalid/local-jcore-5.2.2.zip' }
  s.platform         = :ios, '12.0'
  s.static_framework = true
  s.libraries        = 'resolv'
  s.vendored_frameworks = 'jcore-ios-5.2.2.xcframework'
  s.preserve_paths   = 'jcore-ios-5.2.2.xcframework'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
end
