import Foundation

enum ExpoJpushEvent {
  static let registration = "registration"
  static let messageReceived = "messageReceived"
  static let notificationReceived = "notificationReceived"
  static let notificationOpened = "notificationOpened"
  static let connectionChange = "connectionChange"
  static let localNotificationReceived = "localNotificationReceived"
  static let inAppMessage = "inAppMessage"
  static let tagAliasResult = "tagAliasResult"
  static let mobileNumberResult = "mobileNumberResult"

  static let all: [String] = [
    registration, messageReceived, notificationReceived, notificationOpened,
    connectionChange, localNotificationReceived, inAppMessage,
    tagAliasResult, mobileNumberResult
  ]
}

final class ExpoJpushBridge: NSObject {
  static let shared = ExpoJpushBridge()
  private let logPrefix = "[expo-jpush][ios][bridge]"

  private weak var module: ExpoJpushModule?
  private var isInitialized = false
  private var observersRegistered = false
  private var pendingEvents: [(String, [String: Any])] = []

  private override init() {
    super.init()
  }

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

  // MARK: - Setup

  func setupIfNeeded(options: [String: Any]?) {
    let debug = (options?["debug"] as? Bool) ?? false
    ExpoJpushNativeBridge.setDebugMode(debug)

    guard !isInitialized else { return }

    let appKey = (Bundle.main.object(forInfoDictionaryKey: "ExpoJpushAppKey") as? String) ?? ""
    let channel = (Bundle.main.object(forInfoDictionaryKey: "ExpoJpushChannel") as? String) ?? "default"
    let apsForProduction = (Bundle.main.object(forInfoDictionaryKey: "ExpoJpushApsForProduction") as? Bool) ?? false

    guard !appKey.isEmpty else {
      print("[expo-jpush] Missing Info.plist key: ExpoJpushAppKey")
      return
    }

    ExpoJpushNativeBridge.setup(
      normalizedLaunchOptions(),
      appKey: appKey,
      channel: channel,
      apsForProduction: apsForProduction
    )
    ExpoJpushNativeBridge.registerForRemoteNotification(withDelegate: ExpoJpushAppDelegateSubscriber.shared)
    ExpoJpushNativeBridge.setInAppMessageDelegate(self)

    registerObserversIfNeeded()
    isInitialized = true
    print("\(logPrefix) setup completed")
  }

  func registrationID() -> String {
    return ExpoJpushNativeBridge.registrationID()
  }

  // MARK: - Event Emitting

  func emit(name: String, payload: [String: Any]) {
    guard let module else {
      pendingEvents.append((name, payload))
      return
    }
    module.sendEvent(name, payload)
  }

  // MARK: - Notification Handlers

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

  // MARK: - Tag Operations

  func setTags(_ tags: [String], seq: Int) {
    ExpoJpushNativeBridge.setTags(tags, seq: seq) { [weak self] code, resultTags, resultSeq in
      self?.emitTagResult(code: code, tags: resultTags, seq: resultSeq)
    }
  }

  func addTags(_ tags: [String], seq: Int) {
    ExpoJpushNativeBridge.addTags(tags, seq: seq) { [weak self] code, resultTags, resultSeq in
      self?.emitTagResult(code: code, tags: resultTags, seq: resultSeq)
    }
  }

  func deleteTags(_ tags: [String], seq: Int) {
    ExpoJpushNativeBridge.deleteTags(tags, seq: seq) { [weak self] code, resultTags, resultSeq in
      self?.emitTagResult(code: code, tags: resultTags, seq: resultSeq)
    }
  }

  func cleanTags(seq: Int) {
    ExpoJpushNativeBridge.cleanTags(withSeq: seq) { [weak self] code, resultTags, resultSeq in
      self?.emitTagResult(code: code, tags: resultTags, seq: resultSeq)
    }
  }

  func getAllTags(seq: Int) {
    ExpoJpushNativeBridge.queryAllTags(withSeq: seq) { [weak self] code, resultTags, resultSeq in
      self?.emitTagResult(code: code, tags: resultTags, seq: resultSeq)
    }
  }

  private func emitTagResult(code: Int, tags: [String]?, seq: Int) {
    var payload: [String: Any] = ["code": code, "sequence": seq]
    if let tags = tags {
      payload["tags"] = tags
    }
    emit(name: ExpoJpushEvent.tagAliasResult, payload: payload)
  }

  // MARK: - Alias Operations

  func setAlias(_ alias: String, seq: Int) {
    ExpoJpushNativeBridge.setAlias(alias, seq: seq) { [weak self] code, resultAlias, resultSeq in
      self?.emitAliasResult(code: code, alias: resultAlias, seq: resultSeq)
    }
  }

  func deleteAlias(seq: Int) {
    ExpoJpushNativeBridge.deleteAlias(withSeq: seq) { [weak self] code, resultAlias, resultSeq in
      self?.emitAliasResult(code: code, alias: resultAlias, seq: resultSeq)
    }
  }

  func getAlias(seq: Int) {
    ExpoJpushNativeBridge.queryAlias(withSeq: seq) { [weak self] code, resultAlias, resultSeq in
      self?.emitAliasResult(code: code, alias: resultAlias, seq: resultSeq)
    }
  }

  private func emitAliasResult(code: Int, alias: String?, seq: Int) {
    var payload: [String: Any] = ["code": code, "sequence": seq]
    if let alias = alias {
      payload["alias"] = alias
    }
    emit(name: ExpoJpushEvent.tagAliasResult, payload: payload)
  }

  // MARK: - Mobile Number

  func setMobileNumber(_ number: String) {
    ExpoJpushNativeBridge.setMobileNumber(number) { [weak self] error in
      let code = (error as NSError?)?.code ?? 0
      self?.emit(name: ExpoJpushEvent.mobileNumberResult, payload: ["code": code])
    }
  }

  // MARK: - Page Tracking

  func pageEnterTo(_ pageName: String) {
    ExpoJpushNativeBridge.pageEnter(to: pageName)
  }

  func pageLeave(_ pageName: String) {
    ExpoJpushNativeBridge.pageLeave(pageName)
  }

  // MARK: - Local Notification

  func addLocalNotification(id: String, title: String, content: String, fireTime: Double, extras: [String: Any]?, category: String?) {
    ExpoJpushNativeBridge.addLocalNotification(
      withId: id,
      title: title,
      content: content,
      fireTime: fireTime,
      extras: extras,
      category: category
    )
  }

  func removeLocalNotification(id: String) {
    ExpoJpushNativeBridge.removeLocalNotification(id)
  }

  func clearLocalNotifications() {
    ExpoJpushNativeBridge.clearLocalNotifications()
  }

  // MARK: - NotificationCenter Observers

  private func registerObserversIfNeeded() {
    guard !observersRegistered else { return }
    observersRegistered = true

    let center = NotificationCenter.default
    center.addObserver(
      forName: NSNotification.Name(rawValue: ExpoJpushNativeBridge.networkDidReceiveMessageNotificationName()),
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let userInfo = notification.userInfo as? [String: Any] else { return }
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

  // MARK: - Private Helpers

  private func flushPendingEvents() {
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

// MARK: - JPUSHInAppMessageDelegate（通过 @objc 匹配 JPush SDK 的 selector）

extension ExpoJpushBridge {
  @objc func jPushInAppMessageDidShow(_ inAppMessage: NSObject) {
    emit(name: ExpoJpushEvent.inAppMessage, payload: buildInAppMessagePayload(inAppMessage, eventType: "show"))
  }

  @objc func jPushInAppMessageDidClick(_ inAppMessage: NSObject) {
    emit(name: ExpoJpushEvent.inAppMessage, payload: buildInAppMessagePayload(inAppMessage, eventType: "click"))
  }

  private func buildInAppMessagePayload(_ message: NSObject, eventType: String) -> [String: Any] {
    var payload: [String: Any] = ["eventType": eventType]
    if let msgId = message.value(forKey: "mesageId") as? String {
      payload["messageId"] = msgId
    }
    if let title = message.value(forKey: "title") as? String {
      payload["title"] = title
    }
    if let content = message.value(forKey: "content") as? String {
      payload["content"] = content
    }
    if let target = message.value(forKey: "target") as? [String] {
      payload["target"] = target
    }
    if let clickAction = message.value(forKey: "clickAction") as? String {
      payload["clickAction"] = clickAction
    }
    if let extras = message.value(forKey: "extras") as? [String: Any] {
      payload["extras"] = extras
    }
    return payload
  }
}
