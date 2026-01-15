import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoJpushViewProps } from './ExpoJpush.types';

const NativeView: React.ComponentType<ExpoJpushViewProps> =
  requireNativeView('ExpoJpush');

export default function ExpoJpushView(props: ExpoJpushViewProps) {
  return <NativeView {...props} />;
}
