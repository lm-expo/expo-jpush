import {
  ConfigPlugin,
  withGradleProperties,
  withAppBuildGradle,
} from 'expo/config-plugins';

type JPushConfig = {
  appKey: string;
  channel: string;
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

const withJPush: ConfigPlugin<JPushConfig> = (config, { appKey, channel }) => {
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

  return config;
};

export default withJPush;