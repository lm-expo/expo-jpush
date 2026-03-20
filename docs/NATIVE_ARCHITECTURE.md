# expo-jpush 原生层架构对比

## Android（结构简单）

```
┌─────────────────────────────────────────────────────────────────┐
│  ExpoJpushModule.kt                                              │
│  - 定义 Module（Name, Events, init/getRegistrationID/setBadge）   │
│  - 处理所有 Intent：handleIndent() 统一处理 5 种 action          │
│  - emitOrQueue：有 React 就 sendEvent，否则 pendingEvents         │
└─────────────────────────────────────────────────────────────────┘
         ▲                                    ▲
         │ handleBroadcast(intent)             │ handleIndent(intent)
         │                                    │
┌────────┴────────────┐            ┌──────────┴──────────────┐
│ ExpoJPushBroadcast  │            │ ExpoJPushMessageReceiver │
│ Receiver.kt         │            │ (继承 JPushMessageReceiver) │
│ 系统广播 → 转给 Module │            │ JPush 回调 → emitOrQueue    │
└────────────────────┘            └──────────────────────────┘
```

- **入口单一**：所有事件最终都进 `ExpoJpushModule.handleIndent()` 或 `ExpoJpushModule.emitOrQueue()`。
- **全 Kotlin**：直接调 JPush Android SDK，无需多一层桥。

---

## iOS（为何更复杂）

```
┌─────────────────────────────────────────────────────────────────┐
│  ExpoJpushModule.swift                                           │
│  - 只做 Module 定义，实际逻辑交给 ExpoJpushBridge.shared          │
└─────────────────────────────────────────────────────────────────┘
         │
         │ attach/detach, setupIfNeeded, registrationID, setBadge
         ▼
┌─────────────────────────────────────────────────────────────────┐
│  ExpoJpushBridge.swift (单例)                                    │
│  - 持有 module 引用、pending 事件                                 │
│  - setup：读 Info.plist，调 NativeBridge，注册 Notification 观察者 │
│  - emit / handleNotification / handleCustomMessage / handleConnectionChange │
└─────────────────────────────────────────────────────────────────┘
         │                                              ▲
         │ 调 Obj-C 桥                                   │ 收到通知后回调
         ▼                                              │
┌────────────────────────────┐    ┌────────────────────┴────────────────────┐
│  ExpoJpushNativeBridge.m    │    │  ExpoJpushAppDelegateSubscriber.swift   │
│  (Objective-C)              │    │  - AppDelegate 生命周期                 │
│  - 封装 JPUSHService.h      │    │  - 存 launchOptions                      │
│  - 因 Swift 无法 import     │    │  - 设备 token / 远程通知 / 前台&点击通知   │
│    JPush 模块，用 Obj-C 桥  │    │  - 所有回调里调 NativeBridge + Bridge.emit │
└────────────────────────────┘    └─────────────────────────────────────────┘
```

事件来源有两类：

1. **AppDelegate / 通知中心**  
   `ExpoJpushAppDelegateSubscriber` 实现 `ExpoAppDelegateSubscriber` 和 JPush 的 UNUserNotificationCenter 回调 → 在回调里调 `ExpoJpushNativeBridge` 和 `ExpoJpushBridge.shared.handleNotification/emit`。
2. **JPush 自定义消息 / 连接状态**  
   SDK 通过 `NotificationCenter` 发通知 → `ExpoJpushBridge` 里注册的观察者 → `handleCustomMessage` / `handleConnectionChange` → `emit`。

---

## 为何 iOS 比 Android 复杂

| 点 | Android | iOS |
|----|--------|-----|
| **语言** | 全 Kotlin，直接用 JPush 的 Java/Kotlin API | JPush 是 Obj-C，Swift 不能稳定 `import JPush`，需要 **Obj-C 桥**（NativeBridge） |
| **生命周期** | BroadcastReceiver + JPushMessageReceiver 即可 | 需要 **AppDelegate**（launchOptions、deviceToken、远程通知）+ **ExpoAppDelegateSubscriber** + UNUserNotificationCenter 回调 |
| **事件汇聚** | 一个 Module 一个 `handleIndent` / `emitOrQueue` | **两处**：AppDelegateSubscriber（推送/点击）+ Bridge 的 Notification 观察者（自定义消息/连接） |
| **单例** | Module 的 companion + WeakReference + 静态 pending | **ExpoJpushBridge.shared** 持 module + pending，Module 只在 OnCreate/OnDestroy 里 attach/detach |

所以 iOS 看起来更「散」：  
**Module** 只做定义 → **Bridge** 做配置、事件分发和 pending → **NativeBridge** 做 Obj-C 封装 → **AppDelegateSubscriber** 接系统/JPush 回调。  
这是由 Swift/Obj-C 混编、Expo 的 AppDelegate 订阅机制和 JPush iOS SDK 的接口一起决定的，不是多写了一层业务逻辑。

---

## 文件职责速查

| 平台 | 文件 | 职责 |
|------|------|------|
| Android | `ExpoJpushModule.kt` | Module 定义 + 统一处理 Intent + emitOrQueue |
| Android | `ExpoJPushMessageReceiver.kt` | JPush 回调 → emitOrQueue |
| Android | `ExpoJPushBroadcastReceiver.kt` | 系统广播 → Module.handleBroadcast |
| Android | `constants.kt` | TAG + 事件名常量 |
| iOS | `ExpoJpushModule.swift` | Module 定义，委托给 Bridge |
| iOS | `ExpoJpushBridge.swift` | 单例：配置、emit、pending、Notification 观察者 |
| iOS | `ExpoJpushNativeBridge.m/h` | Obj-C 封装 JPUSHService |
| iOS | `ExpoJpushAppDelegateSubscriber.swift` | AppDelegate + 通知回调 → NativeBridge + Bridge.emit |
