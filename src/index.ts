// Reexport the native module. On web, it will be resolved to ExpoJpushModule.web.ts
// and on native platforms to ExpoJpushModule.ts
export { default } from './ExpoJpushModule';
export * from  './ExpoJpush.types';
