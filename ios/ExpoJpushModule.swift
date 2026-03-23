import ExpoModulesCore

public class ExpoJpushModule: Module {
  private let logPrefix = "[expo-jpush][ios][module]"

  public func definition() -> ModuleDefinition {
    Name("ExpoJpush")

    Events(ExpoJpushEvent.all)

    OnCreate {
      ExpoJpushBridge.shared.attach(module: self)
    }

    OnDestroy {
      ExpoJpushBridge.shared.detach(module: self)
    }

    // ---- 基础 ----

    AsyncFunction("init") { (options: [String: Any]?) -> String in
      ExpoJpushBridge.shared.setupIfNeeded(options: options)
      let registrationId = ExpoJpushBridge.shared.registrationID()
      if !registrationId.isEmpty {
        ExpoJpushBridge.shared.emit(
          name: ExpoJpushEvent.registration,
          payload: ["registrationId": registrationId]
        )
      }
      return registrationId
    }

    AsyncFunction("getRegistrationID") { () -> String in
      return ExpoJpushBridge.shared.registrationID()
    }

    AsyncFunction("setBadgeNumber") { (params: [String: Any]?) in
      let badgeValue = (params?["badge"] as? NSNumber)?.intValue ?? 0
      ExpoJpushNativeBridge.setBadge(Int(badgeValue))
    }

    // ---- Tag 操作 ----

    AsyncFunction("setTags") { (params: [String: Any]) in
      guard let tags = params["tags"] as? [String] else { return }
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.setTags(tags, seq: seq)
    }

    AsyncFunction("addTags") { (params: [String: Any]) in
      guard let tags = params["tags"] as? [String] else { return }
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.addTags(tags, seq: seq)
    }

    AsyncFunction("deleteTags") { (params: [String: Any]) in
      guard let tags = params["tags"] as? [String] else { return }
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.deleteTags(tags, seq: seq)
    }

    AsyncFunction("cleanTags") { (params: [String: Any]) in
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.cleanTags(seq: seq)
    }

    AsyncFunction("getAllTags") { (params: [String: Any]) in
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.getAllTags(seq: seq)
    }

    // ---- Alias 操作 ----

    AsyncFunction("setAlias") { (params: [String: Any]) in
      guard let alias = params["alias"] as? String else { return }
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.setAlias(alias, seq: seq)
    }

    AsyncFunction("deleteAlias") { (params: [String: Any]) in
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.deleteAlias(seq: seq)
    }

    AsyncFunction("getAlias") { (params: [String: Any]) in
      let seq = (params["seq"] as? NSNumber)?.intValue ?? 0
      ExpoJpushBridge.shared.getAlias(seq: seq)
    }

    // ---- 手机号码 ----

    AsyncFunction("setMobileNumber") { (params: [String: Any]) in
      guard let mobileNumber = params["mobileNumber"] as? String else { return }
      ExpoJpushBridge.shared.setMobileNumber(mobileNumber)
    }

    // ---- 应用内消息页面追踪 ----

    AsyncFunction("pageEnterTo") { (params: [String: Any]) in
      guard let pageName = params["pageName"] as? String else { return }
      ExpoJpushBridge.shared.pageEnterTo(pageName)
    }

    AsyncFunction("pageLeave") { (params: [String: Any]) in
      guard let pageName = params["pageName"] as? String else { return }
      ExpoJpushBridge.shared.pageLeave(pageName)
    }

    // ---- 本地通知 ----

    AsyncFunction("addLocalNotification") { (params: [String: Any]) in
      let notifId = (params["id"] as? NSNumber)?.stringValue ?? "0"
      let title = (params["title"] as? String) ?? ""
      let content = (params["content"] as? String) ?? ""
      let fireTime = (params["fireTime"] as? NSNumber)?.doubleValue ?? 0
      let extras = params["extras"] as? [String: Any]
      let category = params["category"] as? String
      ExpoJpushBridge.shared.addLocalNotification(
        id: notifId, title: title, content: content,
        fireTime: fireTime, extras: extras, category: category
      )
    }

    AsyncFunction("removeLocalNotification") { (params: [String: Any]) in
      guard let notifId = params["id"] as? String else { return }
      ExpoJpushBridge.shared.removeLocalNotification(id: notifId)
    }

    AsyncFunction("clearLocalNotifications") { () in
      ExpoJpushBridge.shared.clearLocalNotifications()
    }
  }
}
