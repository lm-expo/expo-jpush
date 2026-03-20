import Foundation

enum ExpoJpushEvent {
  // 设备 registrationId 注册成功
  static let registration = "registration"
  // JPush 自定义消息（非 APNs 直送格式）
  static let messageReceived = "messageReceived"
  // 收到通知（但未必是用户点击打开）
  static let notificationReceived = "notificationReceived"
  // 用户点击/响应后打开通知
  static let notificationOpened = "notificationOpened"
  // 连接状态变化（例如断开/失败等）
  static let connectionChange = "connectionChange"
}

final class ExpoJpushBridge {
  // 单例：用于跨 Module 生命周期缓存配置与 pending 事件
  static let shared = ExpoJpushBridge()
  private let logPrefix = "[expo-jpush][ios][bridge]"

  // 当前挂载到 Expo 的 JS Module（weak，避免循环引用）
  private weak var module: ExpoJpushModule?
  // 是否已经完成原生初始化（setup/注册 delegate/观察者等）
  private var isInitialized = false
  // 是否已经注册 NotificationCenter 观察者
  private var observersRegistered = false
  // Module 尚未 attach 时缓存的待发送事件队列
  private var pendingEvents: [(String, [String: Any])] = []

  private init() {}

  // attach：当 ExpoJpushModule 创建后，把 module 交给桥并 flush pending 事件
  // - module：当前 ExpoJpushModule 实例
  func attach(module: ExpoJpushModule) {
    print("\(logPrefix) attach module")
    self.module = module
    flushPendingEvents()
  }

  // detach：在 Module 销毁时清理桥对 module 的引用
  // - module：要移除的 ExpoJpushModule 实例
  func detach(module: ExpoJpushModule) {
    if self.module === module {
      print("\(logPrefix) detach module")
      self.module = nil
    }
  }

  // setupIfNeeded：只初始化一次 JPush，并注册 remote notification delegate 和 NotificationCenter 观察者
  // - options：来自 JS init 的参数（目前仅读取 debug）
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

  // registrationID：从 JPush 读取当前 device 的 registrationId
  // 返回：registrationId（可能为空字符串）
  func registrationID() -> String {
    let id = ExpoJpushNativeBridge.registrationID()
    print("\(logPrefix) registrationID=\(id)")
    return id
  }

  // emit：向 JS Module 发送事件；如果 module 尚未 attach，就缓存到 pendingEvents
  // - name：事件名（ExpoJpushEvent.*）
  // - payload：事件数据
  func emit(name: String, payload: [String: Any]) {
    guard let module else {
      print("\(logPrefix) queue event name=\(name) payload=\(payload)")
      pendingEvents.append((name, payload))
      return
    }
    print("\(logPrefix) emit event name=\(name) payload=\(payload)")
    module.sendEvent(name, payload)
  }

  // handleCustomMessage：处理 JPush 自定义消息（从 userInfo 中解析 message 与 extras）
  // - userInfo：JPush/SDK 传入的原始键值对
  func handleCustomMessage(_ userInfo: [String: Any]) {
    let message = (userInfo["content"] as? String) ?? ""
    let extras = parseExtras(userInfo["extras"]) ?? [:]
    emit(name: ExpoJpushEvent.messageReceived, payload: [
      "message": message,
      "extras": extras
    ])
  }

  // handleNotification：把通知 userInfo 解析成 JS 需要的统一 payload，再根据 opened 发不同事件
  // - userInfo：通知 payload
  // - opened：true 表示用户响应/点击打开；false 表示仅收到通知
  func handleNotification(_ userInfo: [String: Any], opened: Bool) {
    let payload = buildNotificationPayload(userInfo)
    emit(
      name: opened ? ExpoJpushEvent.notificationOpened : ExpoJpushEvent.notificationReceived,
      payload: payload
    )
  }

  // handleConnectionChange：连接状态变更时发给 JS
  // - connected：当前是否连接正常
  func handleConnectionChange(connected: Bool) {
    emit(name: ExpoJpushEvent.connectionChange, payload: ["connected": connected])
  }

  // registerObserversIfNeeded：注册 NotificationCenter 观察者，用于接收 JPush 内部派发的内部通知
  // - 例如收到自定义消息/登录/断开/注册失败等，然后再转换成 Expo 事件发给 JS
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

  // flushPendingEvents：把缓存的 pendingEvents 依次发送到 JS Module
  private func flushPendingEvents() {
    if !pendingEvents.isEmpty {
      print("\(logPrefix) flushPendingEvents count=\(pendingEvents.count)")
    }
    while !pendingEvents.isEmpty {
      let event = pendingEvents.removeFirst()
      module?.sendEvent(event.0, event.1)
    }
  }

  // buildNotificationPayload：从通知的 userInfo 构造 JS 侧统一结构
  // 返回结构：
  // - title：标题（从 aps.alert.title 解析）
  // - content：正文（从 aps.alert.body 或 subtitle 解析）
  // - extras：除 aps 与若干内部字段外的自定义字段
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

  // parseExtras：extras 字段解析为字典
  // - rawExtras：可能是 [String: Any]，也可能是 JSON 字符串
  // 返回：解析出的 [String: Any]，解析失败则返回 nil
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

  // normalizedLaunchOptions：把 ExpoJpushAppDelegateSubscriber 缓存的 launchOptions 转为 AnyHashable-KeyMap
  // 返回：可能为 nil（launchOptions 尚未缓存）
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
