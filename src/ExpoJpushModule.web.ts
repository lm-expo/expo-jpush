import { registerWebModule, NativeModule } from 'expo';

import { ExpoJpushModuleEvents } from './ExpoJpush.types';

class ExpoJpushModule extends NativeModule<ExpoJpushModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoJpushModule, 'ExpoJpushModule');
