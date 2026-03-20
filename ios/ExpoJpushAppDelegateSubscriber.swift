import ExpoModulesCore
import UIKit
import UserNotifications

@objcMembers
public class ExpoJpushAppDelegateSubscriber: ExpoAppDelegateSubscriber {
  static let shared = ExpoJpushAppDelegateSubscriber()
  static var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  private let logPrefix = "[expo-jpush][ios][appDelegate]"

  // App 启动完成后只会调用一次。
  // 用于缓存 `launchOptions`，以便后续 JPush 初始化时读取。
  public func application(
    _: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // 供 `ExpoJpushBridge.setupIfNeeded(...)` 后续初始化使用。
    Self.launchOptions = launchOptions
    print("\(logPrefix) didFinishLaunching launchOptions=\(String(describing: launchOptions))")
    return true
  }

  // 当系统完成 APNs 注册并返回 deviceToken 时调用。
  // 参数：
  // - application：UIApplication 实例（此处未使用）
  // - deviceToken：APNs 返回的设备 token（会交给 JPush 以关联设备）
  public func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("\(logPrefix) didRegisterForRemoteNotifications tokenLength=\(deviceToken.count)")
    ExpoJpushNativeBridge.registerDeviceToken(deviceToken)
    let registrationId = ExpoJpushNativeBridge.registrationID()
    print("\(logPrefix) registrationId after token=\(registrationId)")
    if !registrationId.isEmpty {
      // 发给 JS 的事件：registration（registrationId）
      ExpoJpushBridge.shared.emit(
        name: ExpoJpushEvent.registration,
        payload: ["registrationId": registrationId]
      )
    }
  }

  // 当 APNs 注册失败时调用。
  // 参数：
  // - error：失败原因
  public func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("\(logPrefix) didFailToRegisterForRemoteNotifications error=\(error.localizedDescription)")
  }

  // 收到远程通知时调用（且应用有后台获取/处理机会）。
  // 参数：
  // - userInfo：通知 payload（键值对）
  // - completionHandler：必须用后台处理结果进行回调
  public func application(
    _: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("\(logPrefix) didReceiveRemoteNotification")
    let payload = normalizeUserInfo(userInfo)
    // 先交给 JPush 做内部解析/路由处理。
    ExpoJpushNativeBridge.handleRemoteNotification(payload)
    // 再转换成 Expo 事件给 JS。
    ExpoJpushBridge.shared.handleNotification(payload, opened: false)
    completionHandler(.newData)
  }

  // JPush 的前台通知展示回调（foreground）。
  // 参数：
  // - center：当前通知中心
  // - notification：UNNotification，用于提取其中的 `userInfo`
  // - completionHandler：用来指定前台展示选项（badge/sound/alert）
  @objc(jpushNotificationCenter:willPresentNotification:withCompletionHandler:)
  public func jpushNotificationCenter(
    _: UNUserNotificationCenter,
    willPresentNotification notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (Int) -> Void
  ) {
    print("\(logPrefix) jpush willPresent notification")
    let payload = normalizeUserInfo(notification.request.content.userInfo)
    // 转发给 JPush，然后发 Expo 事件给 JS。
    ExpoJpushNativeBridge.handleRemoteNotification(payload)
    ExpoJpushBridge.shared.handleNotification(payload, opened: false)
    completionHandler(Int(UNNotificationPresentationOptions.badge.rawValue | UNNotificationPresentationOptions.sound.rawValue | UNNotificationPresentationOptions.alert.rawValue))
  }

  // JPush 的通知响应回调（用户点击通知等）。
  // 参数：
  // - center：当前通知中心
  // - response：UNNotificationResponse，用于提取其中的 `userInfo`
  // - completionHandler：处理完成后回调
  @objc(jpushNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
  public func jpushNotificationCenter(
    _: UNUserNotificationCenter,
    didReceiveNotificationResponse response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("\(logPrefix) jpush didReceive response")
    let payload = normalizeUserInfo(response.notification.request.content.userInfo)
    ExpoJpushNativeBridge.handleRemoteNotification(payload)
    ExpoJpushBridge.shared.handleNotification(payload, opened: true)
    completionHandler()
  }

  // 把来自 iOS/JPush 的 `userInfo` 归一化成 `[String: Any]`，
  // 以便 Swift -> Expo 的事件系统稳定地发给 JS。
  // 参数：
  // - userInfo：键值对，key 可能是 `AnyHashable`
  private func normalizeUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
    var payload: [String: Any] = [:]
    for (key, value) in userInfo {
      payload[String(describing: key)] = value
    }
    return payload
  }
}
