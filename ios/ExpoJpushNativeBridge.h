#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ExpoJpushTagsCallback)(NSInteger code, NSArray<NSString *> *_Nullable tags, NSInteger seq);
typedef void (^ExpoJpushAliasCallback)(NSInteger code, NSString *_Nullable alias, NSInteger seq);
typedef void (^ExpoJpushTagValidCallback)(NSInteger code, NSArray<NSString *> *_Nullable tags, NSInteger seq, BOOL isBind);

@interface ExpoJpushNativeBridge : NSObject

// ---- 基础 ----
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

// ---- NotificationCenter 通知名 ----
+ (NSString *)networkDidReceiveMessageNotificationName;
+ (NSString *)networkDidLoginNotificationName;
+ (NSString *)networkDidCloseNotificationName;
+ (NSString *)networkFailedRegisterNotificationName;

// ---- Tag 操作 ----
+ (void)setTags:(NSArray<NSString *> *)tags seq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion;
+ (void)addTags:(NSArray<NSString *> *)tags seq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion;
+ (void)deleteTags:(NSArray<NSString *> *)tags seq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion;
+ (void)cleanTagsWithSeq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion;
+ (void)getAllTagsWithSeq:(NSInteger)seq completion:(ExpoJpushTagsCallback)completion;

// ---- Alias 操作 ----
+ (void)setAlias:(NSString *)alias seq:(NSInteger)seq completion:(ExpoJpushAliasCallback)completion;
+ (void)deleteAliasWithSeq:(NSInteger)seq completion:(ExpoJpushAliasCallback)completion;
+ (void)getAliasWithSeq:(NSInteger)seq completion:(ExpoJpushAliasCallback)completion;

// ---- 手机号码 ----
+ (void)setMobileNumber:(NSString *)mobileNumber completion:(void (^)(NSError *_Nullable error))completion;

// ---- 应用内消息页面追踪 ----
+ (void)pageEnterTo:(NSString *)pageName;
+ (void)pageLeave:(NSString *)pageName;

// ---- 应用内消息 delegate ----
+ (void)setInAppMessageDelegate:(id)delegate;

// ---- 本地通知 ----
+ (void)addLocalNotificationWithId:(NSString *)identifier
                             title:(NSString *)title
                           content:(NSString *)content
                          fireTime:(NSTimeInterval)fireTime
                            extras:(nullable NSDictionary *)extras
                          category:(nullable NSString *)category;
+ (void)removeLocalNotification:(NSString *)identifier;
+ (void)clearLocalNotifications;

@end

NS_ASSUME_NONNULL_END
