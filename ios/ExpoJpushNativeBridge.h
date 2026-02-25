#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExpoJpushNativeBridge : NSObject

+ (void)setDebugMode:(BOOL)enabled;
+ (void)setup:(nullable NSDictionary *)launchOptions
       appKey:(NSString *)appKey
      channel:(NSString *)channel
apsForProduction:(BOOL)apsForProduction;
+ (void)registerForRemoteNotificationWithDelegate:(nullable id)delegate;
+ (void)registerDeviceToken:(NSData *)deviceToken;
+ (void)handleRemoteNotification:(NSDictionary *)userInfo;
+ (NSString *)registrationID;
+ (void)setBadge:(NSInteger)badge;

+ (NSString *)networkDidReceiveMessageNotificationName;
+ (NSString *)networkDidLoginNotificationName;
+ (NSString *)networkDidCloseNotificationName;
+ (NSString *)networkFailedRegisterNotificationName;

@end

NS_ASSUME_NONNULL_END
