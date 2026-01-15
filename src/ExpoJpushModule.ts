import { NativeModule, requireNativeModule } from 'expo';

import { ExpoJpushModuleEvents } from './ExpoJpush.types';

declare class ExpoJpushModule extends NativeModule<ExpoJpushModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoJpushModule>('ExpoJpush');
