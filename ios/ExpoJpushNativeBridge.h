#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExpoJpushNativeBridge : NSObject

// 开启/关闭 JPush SDK 的调试输出
+ (void)setDebugMode:(BOOL)enabled;

// 初始化 JPush（必须在 App 启动时配置完成）
// 参数：
// - launchOptions：应用启动时的 launchOptions（可为 nil）
// - appKey：JPush 应用 key
// - channel：渠道标识
// - apsForProduction：是否使用生产环境的 APNs（true=production，false=development）
+ (void)setup:(nullable NSDictionary *)launchOptions
       appKey:(NSString *)appKey
      channel:(NSString *)channel
apsForProduction:(BOOL)apsForProduction;

// 向 JPush 注册 remote notification，并把 delegate 对象交给 JPush 回调
// 参数：
// - delegate：实现 JPushRegisterDelegate 对应方法的对象（此项目中为 ExpoJpushAppDelegateSubscriber.shared）
+ (void)registerForRemoteNotificationWithDelegate:(nullable id)delegate;

// 把 APNs deviceToken 交给 JPush（用于注册 registrationId）
+ (void)registerDeviceToken:(NSData *)deviceToken;

// 交给 JPush 处理某次 remote notification 的 userInfo
+ (void)handleRemoteNotification:(NSDictionary *)userInfo;

// 获取 JPush 返回的 registrationId（用于 JS/业务层标识当前设备）
+ (NSString *)registrationID;

// 设置 JPush badge 数
+ (void)setBadge:(NSInteger)badge;

// 以下为 JPush 内部通过 NotificationCenter 发出的通知名称（用于 ExpoJpushBridge 注册观察者）
+ (NSString *)networkDidReceiveMessageNotificationName;
+ (NSString *)networkDidLoginNotificationName;
+ (NSString *)networkDidCloseNotificationName;
+ (NSString *)networkFailedRegisterNotificationName;

@end

NS_ASSUME_NONNULL_END
