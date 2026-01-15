export type OnLoadEventPayload = {
  url: string;
};


export type JPushRegistrationPayload = {
  registrationId: string;
};

export type JPushMessagePayload = {
  message: string;
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

export type ExpoJpushModuleEvents = {
  registration: (payload: JPushRegistrationPayload) => void;
  messageReceived: (payload: JPushMessagePayload) => void;
  notificationReceived: (payload: JPushNotificationPayload) => void;
  notificationOpened: (payload: JPushNotificationPayload) => void;
  connectionChange: (payload: JPushConnectionChangePayload) => void;
};

export type RegistrationEventPayload = {
  registrationId: string;
};

export type MessageReceivedEventPayload = {
  message: string;
  extras: Record<string, any>;
};
