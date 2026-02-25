import ExpoModulesCore

public class ExpoJpushModule: Module {
  private let logPrefix = "[expo-jpush][ios][module]"

  public func definition() -> ModuleDefinition {
    Name("ExpoJpush")

    Events(
      ExpoJpushEvent.registration,
      ExpoJpushEvent.messageReceived,
      ExpoJpushEvent.notificationReceived,
      ExpoJpushEvent.notificationOpened,
      ExpoJpushEvent.connectionChange
    )

    OnCreate {
      ExpoJpushBridge.shared.attach(module: self)
    }

    OnDestroy {
      ExpoJpushBridge.shared.detach(module: self)
    }

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

    AsyncFunction("getRegistrationID") { () -> String in
      let registrationId = ExpoJpushBridge.shared.registrationID()
      print("\(self.logPrefix) getRegistrationID result=\(registrationId)")
      return registrationId
    }

    AsyncFunction("setBadgeNumber") { (params: [String: Any]?) in
      let badgeValue = (params?["badge"] as? NSNumber)?.intValue ?? 0
      ExpoJpushNativeBridge.setBadge(Int(badgeValue))
    }
  }
}
