import * as React from 'react';

import { ExpoJpushViewProps } from './ExpoJpush.types';

export default function ExpoJpushView(props: ExpoJpushViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
