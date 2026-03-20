import ExpoModulesCore

public class ExpoJpushModule: Module {
  private let logPrefix = "[expo-jpush][ios][module]"

  // Expo Module 的注册入口：声明模块名、事件、以及 JS 可调用的方法。
  public func definition() -> ModuleDefinition {
    Name("ExpoJpush")

    // JS 侧可以监听这些事件名（由 ExpoJpushBridge / AppDelegate / JPush 回调触发）
    Events(
      ExpoJpushEvent.registration,
      ExpoJpushEvent.messageReceived,
      ExpoJpushEvent.notificationReceived,
      ExpoJpushEvent.notificationOpened,
      ExpoJpushEvent.connectionChange
    )

    // Module 创建时：把当前 module 实例 attach 给 Bridge，
    // 以便 Bridge 可以向 JS 发事件（包括处理 init 早于 Module 创建时的 pending events）。
    OnCreate {
      ExpoJpushBridge.shared.attach(module: self)
    }

    // Module 销毁时：detach 清理对 module 的引用，避免潜在的无效回调。
    OnDestroy {
      ExpoJpushBridge.shared.detach(module: self)
    }

    // JS 调用：初始化 JPush（读 Info.plist 配置、注册回调并获取 registrationId）。
    // parameters:
    // - options: { debug?: boolean, ... }
    // returns: registrationId 字符串（可能为空）
    AsyncFunction("init") { (options: [String: Any]?) -> String in
      print("\(self.logPrefix) init called with options=\(String(describing: options))")
      ExpoJpushBridge.shared.setupIfNeeded(options: options)
      let registrationId = ExpoJpushBridge.shared.registrationID()
      print("\(self.logPrefix) init result registrationId=\(registrationId)")
      if !registrationId.isEmpty {
        ExpoJpushBridge.shared.emit(
          name: ExpoJpushEvent.registration,
          payload: ["registrationId": registrationId]
        )
      }
      return registrationId
    }

    // JS 调用：获取当前 registrationId（由原生层从 JPush 读取）。
    AsyncFunction("getRegistrationID") { () -> String in
      let registrationId = ExpoJpushBridge.shared.registrationID()
      print("\(self.logPrefix) getRegistrationID result=\(registrationId)")
      return registrationId
    }

    // JS 调用：设置角标数字。
    // parameters:
    // - params.badge: NSNumber/int（未传则默认 0）
    AsyncFunction("setBadgeNumber") { (params: [String: Any]?) in
      let badgeValue = (params?["badge"] as? NSNumber)?.intValue ?? 0
      ExpoJpushNativeBridge.setBadge(Int(badgeValue))
    }
  }
}
