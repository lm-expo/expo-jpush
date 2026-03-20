#import "ExpoJpushNativeBridge.h"
#import "JPUSHService.h"

@implementation ExpoJpushNativeBridge

static NSString * const kExpoJpushNativeLogPrefix = @"[expo-jpush][ios][native]";

// 设置 JPush SDK 的 debug 输出开关
+ (void)setDebugMode:(BOOL)enabled
{
  NSLog(@"%@ setDebugMode enabled=%@", kExpoJpushNativeLogPrefix, enabled ? @"YES" : @"NO");
  if (enabled) {
    [JPUSHService setDebugMode];
  } else {
    [JPUSHService setLogOFF];
  }
}

// 初始化 JPush（必须在 App 启动阶段完成）
// 参数：
// - launchOptions：App 启动时的 launchOptions（可能为 nil）
// - appKey：JPush 的应用 Key
// - channel：渠道标识
// - apsForProduction：true=production APNs；false=development APNs
+ (void)setup:(NSDictionary *)launchOptions
       appKey:(NSString *)appKey
      channel:(NSString *)channel
apsForProduction:(BOOL)apsForProduction
{
  NSLog(@"%@ setup appKeyPrefix=%@ channel=%@ apsForProduction=%@ launchOptions=%@",
        kExpoJpushNativeLogPrefix,
        appKey.length >= 6 ? [appKey substringToIndex:6] : appKey,
        channel,
        apsForProduction ? @"YES" : @"NO",
        launchOptions);
  [JPUSHService setupWithOption:launchOptions
                         appKey:appKey
                        channel:channel
               apsForProduction:apsForProduction];
}

// 注册远程通知，并把 delegate 交给 JPush 回调
// 参数：
// - delegate：实现了 JPUSHRegisterDelegate 所需回调的方法对象
+ (void)registerForRemoteNotificationWithDelegate:(id)delegate
{
  NSLog(@"%@ registerForRemoteNotificationWithDelegate delegate=%@",
        kExpoJpushNativeLogPrefix,
        NSStringFromClass([delegate class]));
  JPUSHRegisterEntity *entity = [[JPUSHRegisterEntity alloc] init];
  entity.types = JPAuthorizationOptionAlert | JPAuthorizationOptionBadge | JPAuthorizationOptionSound;
  [JPUSHService registerForRemoteNotificationConfig:entity delegate:delegate];
}

// 把 APNs deviceToken 交给 JPush，以便生成 registrationId
+ (void)registerDeviceToken:(NSData *)deviceToken
{
  NSLog(@"%@ registerDeviceToken length=%lu", kExpoJpushNativeLogPrefix, (unsigned long)deviceToken.length);
  [JPUSHService registerDeviceToken:deviceToken];
}

// 把收到的 remote notification payload 交给 JPush 处理
+ (void)handleRemoteNotification:(NSDictionary *)userInfo
{
  NSLog(@"%@ handleRemoteNotification userInfo=%@", kExpoJpushNativeLogPrefix, userInfo);
  [JPUSHService handleRemoteNotification:userInfo];
}

// 获取 JPush 返回的 registrationId（设备标识）
+ (NSString *)registrationID
{
  NSString *registrationID = [JPUSHService registrationID];
  NSLog(@"%@ registrationID=%@", kExpoJpushNativeLogPrefix, registrationID ?: @"");
  return registrationID ?: @"";
}

// 设置角标数量（badge）
+ (void)setBadge:(NSInteger)badge
{
  [JPUSHService setBadge:badge];
}

// JPush 内部通过 NotificationCenter 通知“收到自定义消息”的通知名
+ (NSString *)networkDidReceiveMessageNotificationName
{
  return kJPFNetworkDidReceiveMessageNotification;
}

// JPush 内部通过 NotificationCenter 通知“登录成功”的通知名
+ (NSString *)networkDidLoginNotificationName
{
  return kJPFNetworkDidLoginNotification;
}

// JPush 内部通过 NotificationCenter 通知“关闭/断开”的通知名
+ (NSString *)networkDidCloseNotificationName
{
  return kJPFNetworkDidCloseNotification;
}

// JPush 内部通过 NotificationCenter 通知“注册失败”的通知名
+ (NSString *)networkFailedRegisterNotificationName
{
  return kJPFNetworkFailedRegisterNotification;
}

@end
