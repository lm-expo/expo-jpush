Pod::Spec.new do |s|
  s.name             = 'JCore'
  s.version          = '5.2.2'
  s.module_name      = 'JCore'
  s.summary          = 'Local JCore binary for expo-jpush'
  s.description      = 'Local JCore XCFramework packaged with expo-jpush.'
  s.homepage         = 'https://www.jiguang.cn/'
  s.license          = { :type => 'Commercial' }
  s.author           = { 'Jiguang' => 'support@jiguang.cn' }
  # 实际使用本 libs 目录下的 xcframework；需在 App 的 Podfile 里用 pod 'JCore', :path => '.../expo-jpush/ios/libs' 安装，不会从此 URL 下载
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
