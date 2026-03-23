import { registerWebModule, NativeModule } from 'expo';

import { ExpoJpushModuleEvents } from './ExpoJpush.types';

class ExpoJpushModule extends NativeModule<ExpoJpushModuleEvents> {
  async init(): Promise<string> { return ''; }
  async getRegistrationID(): Promise<string> { return ''; }
  async setBadgeNumber(): Promise<void> {}
  async setTags(): Promise<void> {}
  async addTags(): Promise<void> {}
  async deleteTags(): Promise<void> {}
  async cleanTags(): Promise<void> {}
  async getAllTags(): Promise<void> {}
  async setAlias(): Promise<void> {}
  async deleteAlias(): Promise<void> {}
  async getAlias(): Promise<void> {}
  async setMobileNumber(): Promise<void> {}
  async pageEnterTo(): Promise<void> {}
  async pageLeave(): Promise<void> {}
  async addLocalNotification(): Promise<void> {}
  async removeLocalNotification(): Promise<void> {}
  async clearLocalNotifications(): Promise<void> {}
}

export default registerWebModule(ExpoJpushModule, 'ExpoJpushModule');
