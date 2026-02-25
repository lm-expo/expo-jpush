import { registerWebModule, NativeModule } from 'expo';

import { ExpoJpushModuleEvents } from './ExpoJpush.types';

class ExpoJpushModule extends NativeModule<ExpoJpushModuleEvents> {
  async init(): Promise<string> {
    return '';
  }

  async getRegistrationID(): Promise<string> {
    return '';
  }
}

export default registerWebModule(ExpoJpushModule, 'ExpoJpushModule');
