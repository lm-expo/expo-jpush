import { useEvent } from "expo";
import ExpoJpush from "expo-jpush";
import { useEffect, useRef, useState } from "react";
import {
  Alert,
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";

let seq = 0;
const nextSeq = () => ++seq;

export default function App() {
  const [registrationID, setRegistrationID] = useState("");
  const [logs, setLogs] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState("tag1,tag2");
  const [aliasInput, setAliasInput] = useState("testUser");
  const [mobileInput, setMobileInput] = useState("13800138000");
  const [pageInput, setPageInput] = useState("HomePage");
  const scrollRef = useRef<ScrollView>(null);

  const addLog = (msg: string) => {
    const time = new Date().toLocaleTimeString();
    setLogs((prev) => [...prev.slice(-50), `[${time}] ${msg}`]);
    setTimeout(() => scrollRef.current?.scrollToEnd({ animated: true }), 100);
  };

  // ---- 事件监听 ----
  const registrationEvent = useEvent(ExpoJpush, "registration");
  const messageReceivedEvent = useEvent(ExpoJpush, "messageReceived");
  const notificationReceivedEvent = useEvent(ExpoJpush, "notificationReceived");
  const notificationOpenedEvent = useEvent(ExpoJpush, "notificationOpened");
  const connectionChangeEvent = useEvent(ExpoJpush, "connectionChange");
  const localNotifEvent = useEvent(ExpoJpush, "localNotificationReceived");
  const inAppMessageEvent = useEvent(ExpoJpush, "inAppMessage");
  const tagAliasEvent = useEvent(ExpoJpush, "tagAliasResult");
  const mobileNumberEvent = useEvent(ExpoJpush, "mobileNumberResult");

  useEffect(() => {
    if (registrationEvent) {
      console.log("===registrationEvent", registrationEvent);
      addLog(`registration: ${JSON.stringify(registrationEvent)}`);
    }
  }, [registrationEvent]);

  useEffect(() => {
    if (messageReceivedEvent)
      addLog(`messageReceived: ${JSON.stringify(messageReceivedEvent)}`);
  }, [messageReceivedEvent]);

  useEffect(() => {
    if (notificationReceivedEvent)
      addLog(
        `notificationReceived: ${JSON.stringify(notificationReceivedEvent)}`,
      );
  }, [notificationReceivedEvent]);

  useEffect(() => {
    if (notificationOpenedEvent)
      addLog(`notificationOpened: ${JSON.stringify(notificationOpenedEvent)}`);
  }, [notificationOpenedEvent]);

  useEffect(() => {
    if (connectionChangeEvent)
      addLog(`connectionChange: ${JSON.stringify(connectionChangeEvent)}`);
  }, [connectionChangeEvent]);

  useEffect(() => {
    if (localNotifEvent)
      addLog(`localNotification: ${JSON.stringify(localNotifEvent)}`);
  }, [localNotifEvent]);

  useEffect(() => {
    if (inAppMessageEvent)
      addLog(`inAppMessage: ${JSON.stringify(inAppMessageEvent)}`);
  }, [inAppMessageEvent]);

  useEffect(() => {
    if (tagAliasEvent)
      addLog(`tagAliasResult: ${JSON.stringify(tagAliasEvent)}`);
  }, [tagAliasEvent]);

  useEffect(() => {
    if (mobileNumberEvent)
      addLog(`mobileNumberResult: ${JSON.stringify(mobileNumberEvent)}`);
  }, [mobileNumberEvent]);

  // ---- 初始化 ----
  useEffect(() => {
    addLog("初始化 JPush...");
    ExpoJpush.init({ debug: true }).then((id) => {
      setRegistrationID(id);
      addLog(`init 完成, registrationId=${id}`);
    });
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container} ref={scrollRef}>
        <Text style={styles.header}>JPush API 测试</Text>

        {/* ---- 基础 ---- */}
        <Group name="基础">
          <Text style={styles.label}>
            registrationID: {registrationID || "(空)"}
          </Text>
          <Button
            title="getRegistrationID"
            onPress={async () => {
              const id = await ExpoJpush.getRegistrationID();
              setRegistrationID(id);
              addLog(`getRegistrationID: ${id}`);
            }}
          />
          <Spacer />
          <Button
            title="setBadgeNumber(5)"
            onPress={async () => {
              await ExpoJpush.setBadgeNumber({ badge: 5 });
              addLog("setBadgeNumber(5) done");
            }}
          />
          <Spacer />
          <Button
            title="setBadgeNumber(0)"
            onPress={async () => {
              await ExpoJpush.setBadgeNumber({ badge: 0 });
              addLog("setBadgeNumber(0) done");
            }}
          />
        </Group>

        {/* ---- Tag ---- */}
        <Group name="Tag 操作">
          <TextInput
            style={styles.input}
            value={tagInput}
            onChangeText={setTagInput}
            placeholder="输入 tag，逗号分隔"
          />
          <Button
            title="setTags"
            onPress={() => {
              const tags = tagInput.split(",").map((t) => t.trim());
              const s = nextSeq();
              ExpoJpush.setTags({ tags, seq: s });
              addLog(`setTags(${tags}, seq=${s})`);
            }}
          />
          <Spacer />
          <Button
            title="addTags"
            onPress={() => {
              const tags = tagInput.split(",").map((t) => t.trim());
              const s = nextSeq();
              ExpoJpush.addTags({ tags, seq: s });
              addLog(`addTags(${tags}, seq=${s})`);
            }}
          />
          <Spacer />
          <Button
            title="deleteTags"
            onPress={() => {
              const tags = tagInput.split(",").map((t) => t.trim());
              const s = nextSeq();
              ExpoJpush.deleteTags({ tags, seq: s });
              addLog(`deleteTags(${tags}, seq=${s})`);
            }}
          />
          <Spacer />
          <Button
            title="cleanTags"
            onPress={() => {
              const s = nextSeq();
              ExpoJpush.cleanTags({ seq: s });
              addLog(`cleanTags(seq=${s})`);
            }}
          />
          <Spacer />
          <Button
            title="getAllTags"
            onPress={() => {
              const s = nextSeq();
              ExpoJpush.getAllTags({ seq: s });
              addLog(`getAllTags(seq=${s})`);
            }}
          />
        </Group>

        {/* ---- Alias ---- */}
        <Group name="Alias 操作">
          <TextInput
            style={styles.input}
            value={aliasInput}
            onChangeText={setAliasInput}
            placeholder="输入 alias"
          />
          <Button
            title="setAlias"
            onPress={() => {
              const s = nextSeq();
              ExpoJpush.setAlias({ alias: aliasInput, seq: s });
              addLog(`setAlias(${aliasInput}, seq=${s})`);
            }}
          />
          <Spacer />
          <Button
            title="deleteAlias"
            onPress={() => {
              const s = nextSeq();
              ExpoJpush.deleteAlias({ seq: s });
              addLog(`deleteAlias(seq=${s})`);
            }}
          />
          <Spacer />
          <Button
            title="getAlias"
            onPress={() => {
              const s = nextSeq();
              ExpoJpush.getAlias({ seq: s });
              addLog(`getAlias(seq=${s})`);
            }}
          />
        </Group>

        {/* ---- 手机号码 ---- */}
        <Group name="手机号码">
          <TextInput
            style={styles.input}
            value={mobileInput}
            onChangeText={setMobileInput}
            placeholder="输入手机号"
            keyboardType="phone-pad"
          />
          <Button
            title="setMobileNumber"
            onPress={() => {
              ExpoJpush.setMobileNumber({ mobileNumber: mobileInput });
              addLog(`setMobileNumber(${mobileInput})`);
            }}
          />
        </Group>

        {/* ---- 应用内消息 ---- */}
        <Group name="应用内消息 (In-App)">
          <TextInput
            style={styles.input}
            value={pageInput}
            onChangeText={setPageInput}
            placeholder="页面名称"
          />
          <Button
            title="pageEnterTo"
            onPress={() => {
              ExpoJpush.pageEnterTo({ pageName: pageInput });
              addLog(`pageEnterTo(${pageInput})`);
            }}
          />
          <Spacer />
          <Button
            title="pageLeave"
            onPress={() => {
              ExpoJpush.pageLeave({ pageName: pageInput });
              addLog(`pageLeave(${pageInput})`);
            }}
          />
        </Group>

        {/* ---- 本地通知 ---- */}
        <Group name="本地通知">
          <Button
            title="添加本地通知（3秒后触发）"
            onPress={() => {
              ExpoJpush.addLocalNotification({
                id: 12345,
                title: "本地通知测试",
                content: "这是一条 3 秒后触发的本地通知",
                fireTime: 3000,
                extras: { key1: "value1" },
              });
              addLog("addLocalNotification(id=12345, 3s)");
            }}
          />
          <Spacer />
          <Button
            title="移除本地通知(12345)"
            onPress={() => {
              ExpoJpush.removeLocalNotification({ id: "12345" });
              addLog("removeLocalNotification(12345)");
            }}
          />
          <Spacer />
          <Button
            title="清除所有本地通知"
            onPress={() => {
              ExpoJpush.clearLocalNotifications();
              addLog("clearLocalNotifications");
            }}
          />
        </Group>

        {/* ---- 日志 ---- */}
        <Group name="事件日志">
          <View style={styles.logBox}>
            {logs.length === 0 ? (
              <Text style={styles.logEmpty}>暂无日志</Text>
            ) : (
              logs.map((log, i) => (
                <Text key={i} style={styles.logText}>
                  {log}
                </Text>
              ))
            )}
          </View>
          <Spacer />
          <Button title="清空日志" onPress={() => setLogs([])} />
        </Group>

        <View style={{ height: 40 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

function Spacer() {
  return <View style={{ height: 8 }} />;
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f5f5f5",
  },
  header: {
    fontSize: 24,
    fontWeight: "bold",
    margin: 16,
    textAlign: "center",
  },
  group: {
    marginHorizontal: 16,
    marginBottom: 12,
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 16,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  groupHeader: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 12,
    color: "#333",
  },
  label: {
    fontSize: 13,
    color: "#666",
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginBottom: 8,
    fontSize: 14,
  },
  logBox: {
    backgroundColor: "#1e1e1e",
    borderRadius: 8,
    padding: 12,
    maxHeight: 240,
  },
  logText: {
    fontSize: 11,
    color: "#4ec9b0",
    fontFamily: "monospace",
    lineHeight: 16,
  },
  logEmpty: {
    fontSize: 12,
    color: "#888",
    fontStyle: "italic",
  },
});
