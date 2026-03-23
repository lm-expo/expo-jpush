#import "ExpoJpushNativeBridge.h"
#import "JPUSHService.h"
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

NSString * const kExpoJpushInAppMessageShow = @"ExpoJpushInAppMessageShow";
NSString * const kExpoJpushInAppMessageClick = @"ExpoJpushInAppMessageClick";

@interface ExpoJpushInAppMessageHandler : NSObject <JPUSHInAppMessageDelegate>
@end

@implementation ExpoJpushInAppMessageHandler

- (void)jPushInAppMessageDidShow:(JPushInAppMessage *)inAppMessage {
  NSDictionary *info = [ExpoJpushInAppMessageHandler inAppMessageToDict:inAppMessage];
  [[NSNotificationCenter defaultCenter] postNotificationName:kExpoJpushInAppMessageShow object:nil userInfo:info];
}

- (void)jPushInAppMessageDidClick:(JPushInAppMessage *)inAppMessage {
  NSDictionary *info = [ExpoJpushInAppMessageHandler inAppMessageToDict:inAppMessage];
  [[NSNotificationCenter defaultCenter] postNotificationName:kExpoJpushInAppMessageClick object:nil userInfo:info];
}

+ (NSDictionary *)inAppMessageToDict:(JPushInAppMessage *)msg {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (msg.mesageId) dict[@"messageId"] = msg.mesageId;
  if (msg.title) dict[@"title"] = msg.title;
  if (msg.content) dict[@"content"] = msg.content;
  if (msg.target) dict[@"target"] = msg.target;
  if (msg.clickAction) dict[@"clickAction"] = msg.clickAction;
  if (msg.extras) dict[@"extras"] = msg.extras;
  return dict;
}

@end

static ExpoJpushInAppMessageHandler *_inAppHandler = nil;

@implementation ExpoJpushNativeBridge

static NSString * const kLog = @"[expo-jpush][ios][native]";

// ---- 基础 ----

+ (void)setDebugMode:(BOOL)enabled
{
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
  NSLog(@"%@ setup appKey=%@… channel=%@ prod=%@", kLog,
        appKey.length >= 6 ? [appKey substringToIndex:6] : appKey,
        channel, apsForProduction ? @"YES" : @"NO");
  [JPUSHService setupWithOption:launchOptions
                         appKey:appKey
                        channel:channel
               apsForProduction:apsForProduction];
}

+ (void)registerForRemoteNotificationWithDelegate:(id)delegate
{
  JPUSHRegisterEntity *entity = [[JPUSHRegisterEntity alloc] init];
  entity.types = JPAuthorizationOptionAlert | JPAuthorizationOptionBadge | JPAuthorizationOptionSound;
  [JPUSHService registerForRemoteNotificationConfig:entity delegate:delegate];
}

+ (void)registerDeviceToken:(NSData *)deviceToken
{
  [JPUSHService registerDeviceToken:deviceToken];
}

+ (void)handleRemoteNotification:(NSDictionary *)userInfo
{
  [JPUSHService handleRemoteNotification:userInfo];
}

+ (NSString *)registrationID
{
  return [JPUSHService registrationID] ?: @"";
}

+ (void)setBadge:(NSInteger)badge
{
  [JPUSHService setBadge:badge];
  dispatch_async(dispatch_get_main_queue(), ^{
    if (@available(iOS 16.0, *)) {
      [[UNUserNotificationCenter currentNotificationCenter] setBadgeCount:badge withCompletionHandler:nil];
    } else {
      [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
    }
  });
}

// ---- NotificationCenter 通知名 ----

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

// ---- Tag 操作 ----

+ (void)setTags:(NSArray<NSString *> *)tags seq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion
{
  NSSet *tagSet = [NSSet setWithArray:tags];
  [JPUSHService setTags:tagSet completion:^(NSInteger iResCode, NSSet *iTags, NSInteger iSeq) {
    if (completion) completion(iResCode, iTags.allObjects, iSeq);
  } seq:seq];
}

+ (void)addTags:(NSArray<NSString *> *)tags seq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion
{
  NSSet *tagSet = [NSSet setWithArray:tags];
  [JPUSHService addTags:tagSet completion:^(NSInteger iResCode, NSSet *iTags, NSInteger iSeq) {
    if (completion) completion(iResCode, iTags.allObjects, iSeq);
  } seq:seq];
}

+ (void)deleteTags:(NSArray<NSString *> *)tags seq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion
{
  NSSet *tagSet = [NSSet setWithArray:tags];
  [JPUSHService deleteTags:tagSet completion:^(NSInteger iResCode, NSSet *iTags, NSInteger iSeq) {
    if (completion) completion(iResCode, iTags.allObjects, iSeq);
  } seq:seq];
}

+ (void)cleanTagsWithSeq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion
{
  [JPUSHService cleanTags:^(NSInteger iResCode, NSSet *iTags, NSInteger iSeq) {
    if (completion) completion(iResCode, iTags.allObjects, iSeq);
  } seq:seq];
}

+ (void)queryAllTagsWithSeq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion
{
  [JPUSHService getAllTags:^(NSInteger iResCode, NSSet *iTags, NSInteger iSeq) {
    if (completion) completion(iResCode, iTags.allObjects, iSeq);
  } seq:seq];
}

// ---- Alias 操作 ----

+ (void)setAlias:(NSString *)alias seq:(NSInteger)seq completion:(ExpoJpushAliasCallback)completion
{
  [JPUSHService setAlias:alias completion:^(NSInteger iResCode, NSString *iAlias, NSInteger iSeq) {
    if (completion) completion(iResCode, iAlias, iSeq);
  } seq:seq];
}

+ (void)deleteAliasWithSeq:(NSInteger)seq completion:(ExpoJpushAliasCallback)completion
{
  [JPUSHService deleteAlias:^(NSInteger iResCode, NSString *iAlias, NSInteger iSeq) {
    if (completion) completion(iResCode, iAlias, iSeq);
  } seq:seq];
}

+ (void)queryAliasWithSeq:(NSInteger)seq completion:(ExpoJpushAliasCallback)completion
{
  [JPUSHService getAlias:^(NSInteger iResCode, NSString *iAlias, NSInteger iSeq) {
    if (completion) completion(iResCode, iAlias, iSeq);
  } seq:seq];
}

// ---- 手机号码 ----

+ (void)setMobileNumber:(NSString *)mobileNumber completion:(void (^)(NSError *_Nullable error))completion
{
  [JPUSHService setMobileNumber:mobileNumber completion:completion];
}

// ---- 应用内消息页面追踪 ----

+ (void)pageEnterTo:(NSString *)pageName
{
  [JPUSHService pageEnterTo:pageName];
}

+ (void)pageLeave:(NSString *)pageName
{
  [JPUSHService pageLeave:pageName];
}

// ---- 应用内消息 delegate ----

+ (void)registerInAppMessageDelegate
{
  if (!_inAppHandler) {
    _inAppHandler = [[ExpoJpushInAppMessageHandler alloc] init];
  }
  [JPUSHService setInAppMessageDelegate:_inAppHandler];
}

// ---- 本地通知 ----

+ (void)addLocalNotificationWithId:(NSString *)identifier
                             title:(NSString *)title
                           content:(NSString *)content
                          fireTime:(NSTimeInterval)fireTime
                            extras:(NSDictionary *)extras
                          category:(NSString *)category
{
  JPushNotificationContent *notifContent = [[JPushNotificationContent alloc] init];
  notifContent.title = title;
  notifContent.body = content;
  notifContent.sound = @"default";
  if (extras) {
    notifContent.userInfo = extras;
  }
  if (category.length > 0) {
    notifContent.categoryIdentifier = category;
  }

  JPushNotificationTrigger *trigger = [[JPushNotificationTrigger alloc] init];
  if (fireTime > 0) {
    trigger.timeInterval = fireTime / 1000.0;
  }

  JPushNotificationRequest *request = [[JPushNotificationRequest alloc] init];
  request.requestIdentifier = identifier;
  request.content = notifContent;
  request.trigger = trigger;

  [JPUSHService addNotification:request];
}

+ (void)removeLocalNotification:(NSString *)identifier
{
  JPushNotificationIdentifier *notifId = [[JPushNotificationIdentifier alloc] init];
  notifId.identifiers = @[identifier];
  notifId.delivered = NO;
  [JPUSHService removeNotification:notifId];
}

+ (void)clearLocalNotifications
{
  JPushNotificationIdentifier *notifId = [[JPushNotificationIdentifier alloc] init];
  notifId.identifiers = nil;
  notifId.delivered = NO;
  [JPUSHService removeNotification:notifId];
}

@end
