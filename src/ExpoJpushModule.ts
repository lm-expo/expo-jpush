import { NativeModule, requireNativeModule } from 'expo';

import { ExpoJpushModuleEvents } from './ExpoJpush.types';

declare class ExpoJpushModule extends NativeModule<ExpoJpushModuleEvents> {
  init(options: { debug: boolean }): Promise<string>;
  getRegistrationID(): Promise<string>;
}

export default requireNativeModule<ExpoJpushModule>('ExpoJpush');
