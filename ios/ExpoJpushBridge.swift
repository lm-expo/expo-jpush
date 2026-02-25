import Foundation

enum ExpoJpushEvent {
  static let registration = "registration"
  static let messageReceived = "messageReceived"
  static let notificationReceived = "notificationReceived"
  static let notificationOpened = "notificationOpened"
  static let connectionChange = "connectionChange"
}

final class ExpoJpushBridge {
  static let shared = ExpoJpushBridge()
  private let logPrefix = "[expo-jpush][ios][bridge]"

  private weak var module: ExpoJpushModule?
  private var isInitialized = false
  private var observersRegistered = false
  private var pendingEvents: [(String, [String: Any])] = []

  private init() {}

  func attach(module: ExpoJpushModule) {
    print("\(logPrefix) attach module")
    self.module = module
    flushPendingEvents()
  }

  func detach(module: ExpoJpushModule) {
    if self.module === module {
      print("\(logPrefix) detach module")
      self.module = nil
    }
  }

  func setupIfNeeded(options: [String: Any]?) {
    let debug = (options?["debug"] as? Bool) ?? false
    print("\(logPrefix) setupIfNeeded debug=\(debug) isInitialized=\(isInitialized)")
    ExpoJpushNativeBridge.setDebugMode(debug)

    guard !isInitialized else {
      print("\(logPrefix) setup skipped: already initialized")
      return
    }

    let appKey = (Bundle.main.object(forInfoDictionaryKey: "ExpoJpushAppKey") as? String) ?? ""
    let channel = (Bundle.main.object(forInfoDictionaryKey: "ExpoJpushChannel") as? String) ?? "default"
    let apsForProduction = (Bundle.main.object(forInfoDictionaryKey: "ExpoJpushApsForProduction") as? Bool) ?? false

    guard !appKey.isEmpty else {
      print("[expo-jpush] Missing Info.plist key: ExpoJpushAppKey")
      return
    }
    print("\(logPrefix) setup config appKeyPrefix=\(String(appKey.prefix(6))) channel=\(channel) apsForProduction=\(apsForProduction)")

    ExpoJpushNativeBridge.setup(
      normalizedLaunchOptions(),
      appKey: appKey,
      channel: channel,
      apsForProduction: apsForProduction
    )
    ExpoJpushNativeBridge.registerForRemoteNotification(withDelegate: ExpoJpushAppDelegateSubscriber.shared)

    registerObserversIfNeeded()
    isInitialized = true
    print("\(logPrefix) setup completed")
  }

  func registrationID() -> String {
    let id = ExpoJpushNativeBridge.registrationID()
    print("\(logPrefix) registrationID=\(id)")
    return id
  }

  func emit(name: String, payload: [String: Any]) {
    guard let module else {
      print("\(logPrefix) queue event name=\(name) payload=\(payload)")
      pendingEvents.append((name, payload))
      return
    }
    print("\(logPrefix) emit event name=\(name) payload=\(payload)")
    module.sendEvent(name, payload)
  }

  func handleCustomMessage(_ userInfo: [String: Any]) {
    let message = (userInfo["content"] as? String) ?? ""
    let extras = parseExtras(userInfo["extras"]) ?? [:]
    emit(name: ExpoJpushEvent.messageReceived, payload: [
      "message": message,
      "extras": extras
    ])
  }

  func handleNotification(_ userInfo: [String: Any], opened: Bool) {
    let payload = buildNotificationPayload(userInfo)
    emit(
      name: opened ? ExpoJpushEvent.notificationOpened : ExpoJpushEvent.notificationReceived,
      payload: payload
    )
  }

  func handleConnectionChange(connected: Bool) {
    emit(name: ExpoJpushEvent.connectionChange, payload: ["connected": connected])
  }

  private func registerObserversIfNeeded() {
    guard !observersRegistered else {
      print("\(logPrefix) observers already registered")
      return
    }
    observersRegistered = true
    print("\(logPrefix) register observers")

    let center = NotificationCenter.default
    center.addObserver(
      forName: NSNotification.Name(rawValue: ExpoJpushNativeBridge.networkDidReceiveMessageNotificationName()),
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let userInfo = notification.userInfo as? [String: Any] else {
        return
      }
      self?.handleCustomMessage(userInfo)
    }

    center.addObserver(
      forName: NSNotification.Name(rawValue: ExpoJpushNativeBridge.networkDidLoginNotificationName()),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleConnectionChange(connected: true)
    }

    center.addObserver(
      forName: NSNotification.Name(rawValue: ExpoJpushNativeBridge.networkDidCloseNotificationName()),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleConnectionChange(connected: false)
    }

    center.addObserver(
      forName: NSNotification.Name(rawValue: ExpoJpushNativeBridge.networkFailedRegisterNotificationName()),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleConnectionChange(connected: false)
    }
  }

  private func flushPendingEvents() {
    if !pendingEvents.isEmpty {
      print("\(logPrefix) flushPendingEvents count=\(pendingEvents.count)")
    }
    while !pendingEvents.isEmpty {
      let event = pendingEvents.removeFirst()
      module?.sendEvent(event.0, event.1)
    }
  }

  private func buildNotificationPayload(_ userInfo: [String: Any]) -> [String: Any] {
    let aps = userInfo["aps"] as? [String: Any]
    let alertValue = aps?["alert"]

    var title: String?
    var content: String?

    if let alert = alertValue as? String {
      content = alert
    } else if let alert = alertValue as? [String: Any] {
      title = alert["title"] as? String
      content = (alert["body"] as? String) ?? (alert["subtitle"] as? String)
    }

    var extras: [String: Any] = [:]
    for (key, value) in userInfo {
      if key == "aps" || key == "_j_msgid" || key == "_j_uid" || key == "_j_business" {
        continue
      }
      extras[key] = value
    }

    return [
      "title": title ?? NSNull(),
      "content": content ?? NSNull(),
      "extras": extras.isEmpty ? NSNull() : extras
    ]
  }

  private func parseExtras(_ rawExtras: Any?) -> [String: Any]? {
    if let extras = rawExtras as? [String: Any] {
      return extras
    }
    guard let extrasString = rawExtras as? String, let data = extrasString.data(using: .utf8) else {
      return nil
    }
    let object = try? JSONSerialization.jsonObject(with: data)
    return object as? [String: Any]
  }

  private func normalizedLaunchOptions() -> [AnyHashable: Any]? {
    guard let launchOptions = ExpoJpushAppDelegateSubscriber.launchOptions else {
      return nil
    }
    var normalized: [AnyHashable: Any] = [:]
    for (key, value) in launchOptions {
      normalized[key.rawValue] = value
    }
    return normalized
  }
}
