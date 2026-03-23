import { NativeModule, requireNativeModule } from "expo";

import { ExpoJpushModuleEvents } from "./ExpoJpush.types";

declare class ExpoJpushModule extends NativeModule<ExpoJpushModuleEvents> {
  /** 初始化 JPush 并返回当前设备的 registrationId */
  init(options: { debug: boolean }): Promise<string>;

  /** 获取当前设备的 registrationId */
  getRegistrationID(): Promise<string>;

  /** 设置角标数量 */
  setBadgeNumber(params: { badge: number }): Promise<void>;

  // ---- Tag 操作 ----

  /** 覆盖设置 tags（会替换现有全部 tags） */
  setTags(params: { tags: string[]; seq: number }): Promise<void>;

  /** 新增 tags（追加到现有 tags） */
  addTags(params: { tags: string[]; seq: number }): Promise<void>;

  /** 删除指定 tags */
  deleteTags(params: { tags: string[]; seq: number }): Promise<void>;

  /** 清空所有 tags */
  cleanTags(params: { seq: number }): Promise<void>;

  /** 查询全部 tags */
  getAllTags(params: { seq: number }): Promise<void>;

  // ---- Alias 操作 ----

  /** 设置 alias */
  setAlias(params: { alias: string; seq: number }): Promise<void>;

  /** 删除 alias */
  deleteAlias(params: { seq: number }): Promise<void>;

  /** 查询当前 alias */
  getAlias(params: { seq: number }): Promise<void>;

  // ---- 手机号码 ----

  /** 设置手机号码（用于"推送不到短信到"功能） */
  setMobileNumber(params: { mobileNumber: string }): Promise<void>;

  // ---- 应用内消息页面追踪 ----

  /** 进入页面（配合应用内消息使用，需与 pageLeave 配套调用） */
  pageEnterTo(params: { pageName: string }): Promise<void>;

  /** 离开页面（配合应用内消息使用，需与 pageEnterTo 配套调用） */
  pageLeave(params: { pageName: string }): Promise<void>;

  // ---- 本地通知 ----

  /** 添加本地通知 */
  addLocalNotification(params: {
    /** 通知 ID（整数） */
    id: number;
    title: string;
    content: string;
    /** 触发延迟（毫秒），相对当前时间。例如 3000 = 3秒后触发 */
    fireTime: number;
    extras?: Record<string, unknown>;
    /** Android 自定义通知布局文件名 */
    builderName?: string;
    /** 通知分类（Android: category；iOS: categoryIdentifier） */
    category?: string;
    /** Android 通知优先级 */
    priority?: number;
  }): Promise<void>;

  /** 移除指定本地通知 */
  removeLocalNotification(params: { id: string }): Promise<void>;

  /** 清除所有本地通知 */
  clearLocalNotifications(): Promise<void>;
}

export default requireNativeModule<ExpoJpushModule>("ExpoJpush");
