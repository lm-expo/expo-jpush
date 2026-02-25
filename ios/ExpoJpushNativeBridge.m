#import "ExpoJpushNativeBridge.h"
#import "JPUSHService.h"

@implementation ExpoJpushNativeBridge

static NSString * const kExpoJpushNativeLogPrefix = @"[expo-jpush][ios][native]";

+ (void)setDebugMode:(BOOL)enabled
{
  NSLog(@"%@ setDebugMode enabled=%@", kExpoJpushNativeLogPrefix, enabled ? @"YES" : @"NO");
  if (enabled) {
    [JPUSHService setDebugMode];
  } else {
    [JPUSHService setLogOFF];
  }
}

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

+ (void)registerForRemoteNotificationWithDelegate:(id)delegate
{
  NSLog(@"%@ registerForRemoteNotificationWithDelegate delegate=%@",
        kExpoJpushNativeLogPrefix,
        NSStringFromClass([delegate class]));
  JPUSHRegisterEntity *entity = [[JPUSHRegisterEntity alloc] init];
  entity.types = JPAuthorizationOptionAlert | JPAuthorizationOptionBadge | JPAuthorizationOptionSound;
  [JPUSHService registerForRemoteNotificationConfig:entity delegate:delegate];
}

+ (void)registerDeviceToken:(NSData *)deviceToken
{
  NSLog(@"%@ registerDeviceToken length=%lu", kExpoJpushNativeLogPrefix, (unsigned long)deviceToken.length);
  [JPUSHService registerDeviceToken:deviceToken];
}

+ (void)handleRemoteNotification:(NSDictionary *)userInfo
{
  NSLog(@"%@ handleRemoteNotification userInfo=%@", kExpoJpushNativeLogPrefix, userInfo);
  [JPUSHService handleRemoteNotification:userInfo];
}

+ (NSString *)registrationID
{
  NSString *registrationID = [JPUSHService registrationID];
  NSLog(@"%@ registrationID=%@", kExpoJpushNativeLogPrefix, registrationID ?: @"");
  return registrationID ?: @"";
}

+ (void)setBadge:(NSInteger)badge
{
  [JPUSHService setBadge:badge];
}

+ (NSString *)networkDidReceiveMessageNotificationName
{
  return kJPFNetworkDidReceiveMessageNotification;
}

+ (NSString *)networkDidLoginNotificationName
{
  return kJPFNetworkDidLoginNotification;
}

+ (NSString *)networkDidCloseNotificationName
{
  return kJPFNetworkDidCloseNotification;
}

+ (NSString *)networkFailedRegisterNotificationName
{
  return kJPFNetworkFailedRegisterNotification;
}

@end
