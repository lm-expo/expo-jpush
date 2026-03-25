# expo-jpush

Expo JPush module for Expo / React Native projects.

# API documentation

- [Documentation for the latest stable release](https://docs.expo.dev/versions/latest/sdk/jpush/)
- [Documentation for the main branch](https://docs.expo.dev/versions/unversioned/sdk/jpush/)

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```bash
npm install lm-expo-jpush
```

### Configure for Android




### Configure for iOS

Run `npx pod-install` after installing the npm package.

# Publish to npm

This repository is configured to publish to the public npm registry:

```bash
npm install
npm run build
npm run build:plugin
npm pack --dry-run
```

After verifying the package contents, bump the version and publish:

```bash
npm version patch
npm publish
```

# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide]( https://github.com/expo/expo#contributing).
