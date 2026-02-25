import {
  ConfigPlugin,
  withGradleProperties,
  withAppBuildGradle,
  withInfoPlist,
  withEntitlementsPlist,
} from 'expo/config-plugins';

type JPushConfig = {
  appKey: string;
  channel: string;
  ios?: {
    apsForProduction?: boolean;
    apsEnvironment?: 'development' | 'production';
  };
};

const PLACEHOLDERS_TAG_START = '// expo-jpush:manifestPlaceholders:start';
const PLACEHOLDERS_TAG_END = '// expo-jpush:manifestPlaceholders:end';
const PLACEHOLDERS_INNER_BLOCK = `
${PLACEHOLDERS_TAG_START}
manifestPlaceholders += [
    JPUSH_APPKEY : project.findProperty("JPUSH_APPKEY") ?: "",
    JPUSH_CHANNEL: project.findProperty("JPUSH_CHANNEL") ?: "default"
]
${PLACEHOLDERS_TAG_END}
`;

const IOS_INFO_PLIST_APP_KEY = 'ExpoJpushAppKey';
const IOS_INFO_PLIST_CHANNEL = 'ExpoJpushChannel';
const IOS_INFO_PLIST_APS_FOR_PRODUCTION = 'ExpoJpushApsForProduction';

const withJPush: ConfigPlugin<JPushConfig> = (config, props) => {
  const { appKey, channel, ios } = props;
  const apsForProduction = ios?.apsForProduction ?? false;
  const apsEnvironment = ios?.apsEnvironment ?? (apsForProduction ? 'production' : 'development');

  /**
   * 1️⃣ 写入 android/gradle.properties
   */
  config = withGradleProperties(config, config => {
    const props: any[] = config.modResults;

    const upsert = (key: string, value: string) => {
      const existing = props.find(p => p.key === key);
      if (existing) {
        existing.value = value;
      } else {
        props.push({ type: 'property', key, value });
      }
    };

    upsert('JPUSH_APPKEY', appKey);
    upsert('JPUSH_CHANNEL', channel);

    return config;
  });

  /**
   * 2️⃣ 注入 manifestPlaceholders 到 app/build.gradle
   */
  config = withAppBuildGradle(config, config => {
    let contents = config.modResults.contents;

    // 已存在则直接返回
    if (contents.includes(PLACEHOLDERS_TAG_START)) {
      return config;
    }

    // 插入到 `defaultConfig { ... }` 中使用捕获的缩进。 避免覆盖其他插件和避免插入到字符串字面量中。
    const reDefaultConfig = /^(\s*)defaultConfig\s*\{/m;
    contents = contents.replace(reDefaultConfig, (match, indent: string) => {
      const innerIndent = `${indent}    `;
      const indentedBlock = PLACEHOLDERS_INNER_BLOCK.trim()
        .split('\n')
        .map(line => `${innerIndent}${line}`)
        .join('\n');
      return `${match}\n${indentedBlock}`;
    });

    config.modResults.contents = contents;
    return config;
  });

  /**
   * 3️⃣ 写入 iOS Info.plist，供 Native SDK 初始化读取
   */
  config = withInfoPlist(config, config => {
    config.modResults[IOS_INFO_PLIST_APP_KEY] = appKey;
    config.modResults[IOS_INFO_PLIST_CHANNEL] = channel;
    config.modResults[IOS_INFO_PLIST_APS_FOR_PRODUCTION] = apsForProduction;

    const backgroundModes = new Set(config.modResults.UIBackgroundModes ?? []);
    backgroundModes.add('remote-notification');
    config.modResults.UIBackgroundModes = Array.from(backgroundModes);

    return config;
  });

  /**
   * 4️⃣ 写入 iOS push entitlement
   */
  config = withEntitlementsPlist(config, config => {
    config.modResults['aps-environment'] = apsEnvironment;
    return config;
  });

  return config;
};

export default withJPush;