import ExpoModulesCore
import UIKit
import UserNotifications

@objcMembers
public class ExpoJpushAppDelegateSubscriber: ExpoAppDelegateSubscriber {
  static let shared = ExpoJpushAppDelegateSubscriber()
  static var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  private let logPrefix = "[expo-jpush][ios][appDelegate]"

  public func application(
    _: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    Self.launchOptions = launchOptions
    print("\(logPrefix) didFinishLaunching launchOptions=\(String(describing: launchOptions))")
    return true
  }

  public func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("\(logPrefix) didRegisterForRemoteNotifications tokenLength=\(deviceToken.count)")
    ExpoJpushNativeBridge.registerDeviceToken(deviceToken)
    let registrationId = ExpoJpushNativeBridge.registrationID()
    print("\(logPrefix) registrationId after token=\(registrationId)")
    if !registrationId.isEmpty {
      ExpoJpushBridge.shared.emit(
        name: ExpoJpushEvent.registration,
        payload: ["registrationId": registrationId]
      )
    }
  }

  public func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("\(logPrefix) didFailToRegisterForRemoteNotifications error=\(error.localizedDescription)")
  }

  public func application(
    _: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("\(logPrefix) didReceiveRemoteNotification")
    let payload = normalizeUserInfo(userInfo)
    ExpoJpushNativeBridge.handleRemoteNotification(payload)
    ExpoJpushBridge.shared.handleNotification(payload, opened: false)
    completionHandler(.newData)
  }

  @objc(jpushNotificationCenter:willPresentNotification:withCompletionHandler:)
  public func jpushNotificationCenter(
    _: UNUserNotificationCenter,
    willPresentNotification notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (Int) -> Void
  ) {
    print("\(logPrefix) jpush willPresent notification")
    let payload = normalizeUserInfo(notification.request.content.userInfo)
    ExpoJpushNativeBridge.handleRemoteNotification(payload)
    ExpoJpushBridge.shared.handleNotification(payload, opened: false)
    completionHandler(Int(UNNotificationPresentationOptions.badge.rawValue | UNNotificationPresentationOptions.sound.rawValue | UNNotificationPresentationOptions.alert.rawValue))
  }

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

  private func normalizeUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
    var payload: [String: Any] = [:]
    for (key, value) in userInfo {
      payload[String(describing: key)] = value
    }
    return payload
  }
}
