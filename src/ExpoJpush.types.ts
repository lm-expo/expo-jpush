export type JPushRegistrationPayload = {
  registrationId: string;
};

export type JPushMessagePayload = {
  message: string;
  title?: string | null;
  extras?: Record<string, unknown> | null;
};

export type JPushNotificationPayload = {
  title?: string | null;
  content?: string | null;
  extras?: Record<string, unknown> | null;
};

export type JPushConnectionChangePayload = {
  connected: boolean;
};

export type JPushLocalNotificationPayload = {
  title?: string | null;
  content?: string | null;
  extras?: Record<string, unknown> | null;
};

export type JPushInAppMessagePayload = {
  eventType: "show" | "click";
  messageId?: string | null;
  title?: string | null;
  content?: string | null;
  target?: string[] | null;
  clickAction?: string | null;
  extras?: Record<string, unknown> | null;
};

export type JPushTagAliasResultPayload = {
  code: number;
  sequence: number;
  tags?: string[] | null;
  alias?: string | null;
  isBind?: boolean | null;
};

export type JPushMobileNumberResultPayload = {
  code: number;
  sequence?: number | null;
};

export type ExpoJpushModuleEvents = {
  registration: (payload: JPushRegistrationPayload) => void;
  messageReceived: (payload: JPushMessagePayload) => void;
  notificationReceived: (payload: JPushNotificationPayload) => void;
  notificationOpened: (payload: JPushNotificationPayload) => void;
  connectionChange: (payload: JPushConnectionChangePayload) => void;
  localNotificationReceived: (payload: JPushLocalNotificationPayload) => void;
  inAppMessage: (payload: JPushInAppMessagePayload) => void;
  tagAliasResult: (payload: JPushTagAliasResultPayload) => void;
  mobileNumberResult: (payload: JPushMobileNumberResultPayload) => void;
};
