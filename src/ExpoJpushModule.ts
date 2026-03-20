import { NativeModule, requireNativeModule } from "expo";

import { ExpoJpushModuleEvents } from "./ExpoJpush.types";

/**
 * 这是 Expo JS 侧对原生模块 `ExpoJpush` 的类型声明与导出。
 * 通过 `requireNativeModule("ExpoJpush")` 获取原生实现，并让 TS 能提示事件/方法的类型。
 */
declare class ExpoJpushModule extends NativeModule<ExpoJpushModuleEvents> {
  /**
   * 初始化 JPush 并返回当前设备的 `registrationId`。
   * @param options
   * @param options.debug 是否打开原生 debug 日志
   */
  init(options: { debug: boolean }): Promise<string>;

  /**
   * 获取当前设备的 `registrationId`。
   */
  getRegistrationID(): Promise<string>;

  /**
   * 设置角标数量（badge）。
   * @param params
   * @param params.badge 角标值（int）
   */
  setBadgeNumber(params: { badge: number }): Promise<void>;
}

// 导出 JS 侧可直接调用的原生模块实例
export default requireNativeModule<ExpoJpushModule>("ExpoJpush");
