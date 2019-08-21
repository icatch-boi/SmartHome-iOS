//
//  SHUtilsMacro.h
//  SmartHome
//
//  Created by ZJ on 2017/4/14.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#ifndef SHUtilsMacro_h
#define SHUtilsMacro_h

typedef NS_ENUM(NSUInteger, SHLogTag) {
    SHLogTagSDK   = 0,
    SHLogTagAPP   = 1,
};

// SmartHome debug toggle
#pragma mark - debug toggle
#define SDK_DEBUG 0
#define APP_DEBUG 0
#define SHLOG_ENABLE 1

#pragma mark - SmartHomeLogMacro
//  SHLogEnable Logging
#if SHLOG_ENABLE
#define SH_LOG_MACRO(_level, Tag, fmt, ...) do { \
NSString *info = [NSString stringWithFormat:@"%s(%d)", __func__, __LINE__]; \
if (Tag == SHLogTagAPP) { \
NSLog((@"app %@: " fmt @" => [ %@ ]"), _level, ##__VA_ARGS__, info); \
} else { \
NSLog((@"sdk %@: " fmt @" => [ %@ ]"), _level, ##__VA_ARGS__, info); \
} \
} while(0)
#else
#define SH_LOG_MACRO(_level, Tag, fmt, ...)
#endif

#define SHLogError(tag, fmt, ...)   SH_LOG_MACRO(@"error", tag, fmt, ##__VA_ARGS__)
#define SHLogWarn(tag, fmt, ...)    SH_LOG_MACRO(@"warn ",  tag, fmt, ##__VA_ARGS__)
#define SHLogInfo(tag, fmt, ...)    SH_LOG_MACRO(@"info ", tag, fmt, ##__VA_ARGS__)
#define SHLogTRACE() SHLogInfo(SHLogTagAPP, @"app run trace.")

// Debug Logging
#if APP_DEBUG
#define SHLogDebug(tag, fmt, ...)   SH_LOG_MACRO(@"debug", tag, fmt, ##__VA_ARGS__)
#else
#define SHLogDebug(tag, fmt, ...)
#endif

#pragma mark - Others
// Check App version
#define APP_VERSION [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
#define APP_BUILDNUMBER [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
#define APP_NAME [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]

// Check iOS version
#define SYSTEM_VERSION_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define ACTION_SHEET_DOWNLOAD_ACTIONS 2014
#define ACTION_SHEET_DELETE_ACTIONS   (ACTION_SHEET_DOWNLOAD_ACTIONS + 1)

#define APP_CONNECT_ERROR_TAG 1024
#define APP_RECONNECT_ALERT_TAG (APP_CONNECT_ERROR_TAG + 1)
#define APP_CUSTOMER_ALERT_TAG  (APP_CONNECT_ERROR_TAG + 2)
#define APP_TIMEOUT_ALERT_TAG  (APP_CONNECT_ERROR_TAG + 3)
#define APP_INPUTIPADDR_ALERT_TAG  (APP_CONNECT_ERROR_TAG + 4)

#define kAppAlertTag 2048
#define kAppFormatSDCardAlertTag (kAppAlertTag + 1)
#define kAppCleanSpaceAlertTag (kAppAlertTag + 2)
#define kAppFactoryResetAlertTag (kAppAlertTag + 3)

const int UNDEFINED_NUM = 0xffff;

#define HW_DECODE_H264
#define USE_SYSTEM_IOS7_IMPLEMENTATION 0
#define USE_SDK_EVENT_DISCONNECTED 0

#define kButtonRadius 15.0
#define kViewRadius 2.5
#define kImageCornerRadius 5.0
#define kBackgroundColor [UIColor ic_colorWithRed:69 green:90 blue:100] // [UIColor colorWithRed:69 / 255.0 green:90 / 255.0 blue:100 / 255.0 alpha:1.0]
#define kDateFormat @"yyyy/MM/dd HH:mm:ss"
#define kScreenSize [UIScreen screenBounds]
#define kShowDownloadCompleteNoteTime 5.0

#define kPushMessageNotification @"kPushMessageNotification"
#define kEnterBackgroundNotification @"kEnterBackgroundNotification"
#define kDownloadCompleteNotification @"kDownloadCompleteNotification"
#define kSingleDownloadCompleteNotification @"kSingleDownloadCompleteNotification"
#define kCameraAlreadyExistNotification @"kCameraAlreadyExistNotification"

#pragma mark - Project
static NSString * const kEnterAPMode = @"kEnterAPMode";
static NSString * const kCameraSSIDPrefix = @"SH-IPC_";
static NSString * const kPowerOffEventValue = @"kPowerOffEventValue";
static NSString * const kAppGroupsName = @"group.com.icatchtek.smarthome";
static NSString * const kShareCameraInfoKey = @"SHShareCameras";
static NSString * const kDeviceToken = @"deviceToken";
static NSString * const kCurrentAddCameraUID = @"CurrentAddCameraUID";
static NSString * const kLocalAlbumName = @"SmartHome";
static NSString * const kSubscribeCameraName = @"SubscribeCameraName";
static NSString * const kReconfigureDevice = @"ReconfigureDevice";
static NSString * const kNewMessageCountKeyPath = @"newMessageCount";

#pragma mark - Local Notification
static NSString * const kAddCameraExitNotification = @"kAddCameraExitNotification";
static NSString * const kCameraDisconnectNotification = @"kCameraDisconnectNotification";
static NSString * const kCameraNetworkConnectedNotification = @"kCameraNetworkConnectedNotification";
static NSString * const kCameraPowerOffNotification = @"kCameraPowerOffNotification";
static NSString * const kUserShouldLoginNotification = @"kUserShouldLoginNotification";
static NSString * const kLoginSuccessNotification = @"kLoginSuccessNotification";
static NSString * const kUpdateDeviceInfoNotification = @"UpdateDeviceInfoNotification";
static NSString * const kDeviceUpgradeFailedNotification = @"DeviceUpgradeFailedNotification";
static NSString * const kDeviceUpgradeSuccessNotification = @"DeviceUpgradeSuccessNotification";
static NSString * const kDownloadUpgradePackageSuccessNotification = @"DownloadUpgradePackageSuccessNotification";
static NSString * const kRecvVideoTimeoutNotification = @"RecvVideoTimeoutNotification";

#pragma mark - Color
static NSUInteger const kThemeColor = 0xFA3336; //0xDE2F43; //0xF2F2F2; //0x00BFD2;
static NSUInteger const kButtonThemeColor = 0x333333; //0x000000; //0x076EE4;
static NSUInteger const kButtonDefaultColor = 0x9b9b9b;
static NSUInteger const kTextThemeColor = 0x333333;
static NSUInteger const kBackgroundThemeColor = 0xF2F2F2;
static NSUInteger const kTextColor = 0x47525E;

#pragma mark - Storyboard
static NSString * const kUserAccountStoryboardName = @"UserAccount";
static NSString * const kSetupStoryboardName = @"Setup";
static NSString * const kSettingStoryboardName = @"Setting";
static NSString * const kAlbumStoryboardName = @"Album";
static NSString * const kMainStoryboardName = @"XJMain";
static NSString * const kMessageCenterStoryboardName = @"MessageCenter";
static NSString * const kFaceRecognitionStoryboardName = @"FaceRecognition";

#pragma mark - RegularExpression
static NSString * const kPhoneRegularExpression = @"^1(3[0-9]|4[579]|5[0-35-9]|7[01356]|8[0-9]|9[9])\\d{8}$";
static NSString * const kEmailRegularExpression = @"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
static NSString * const kPasswordRegularExpression = @"[A-Za-z0-9_()?![，。？：；’‘！”“、`~!@#$%^&*()-_=+<>./]]{%zd,%zd}";
static const NSInteger kPasswordMinLength = 8;
static const NSInteger kPasswordMaxLength = 16;
static NSString * const kDeviceNameRegularExpression = @"[\u4e00-\u9fa5a-zA-Z0-9_-]{%lu,%lu}";
static const NSUInteger kDeviceNameMinLength = 3;
static const NSUInteger kDeviceNameMaxLength = 12;

#pragma mark - Others
static NSTimeInterval const kDataBaseFileStorageTime = 7 * 24 * 3600;
static NSString * const kUserAccounts = @"kUserAccounts";
static NSString * const kRecvNotificationCount = @"kRecvNotificationCount";
static NSString * const kRecvNotification = @"RecvNotification";
static int const kNetworkDetectionInterval = 2.0; //5.0;
static const float kMinZoomScale = 1.0;
static const float kMaxZoomScale = 5.0;
static const NSInteger kQRCodeValidDuration = 24; //hours
static const NSInteger kDeviceValidUsedDuration = 7; //days
static const BOOL kUseTUTKPushServer = NO;

#pragma mark - Config Account Server
static NSString * const kServerBaseURL = @"https://account.smarthome.icatchtek.com:3027/";
static NSString * const kServerClientID = @"icatch_smarthome";
static NSString * const kServerClientSecret = @"123456";
static NSString * const kServerCustomerID = @"5aa0d55246c14813a2313c17";

#define kScreenWidthScale MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) / 320.0
#define kScreenHeightScale MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width) / 480.0

#define WEAK_SELF(obj) __weak typeof(obj) weak##obj = obj;
#define STRONG_SELF(obj) __strong typeof(obj) obj = weak##obj;

typedef enum : NSUInteger {
    PushMessageTypePir = 100,
    PushMessageTypeLowPower = 102,
    PushMessageTypeSDCardFull = 103,
    PushMessageTypeSDCardError = 104,
    PushMessageTypeTamperAlarm = 105,
    PushMessageTypeRing = 201,
    PushMessageTypeFDHit = 202,
    PushMessageTypeFDMiss = 203,
    PushMessageTypePushTest = 204,
    PushMessageTypeFaceRecognition = 301,
} PushMessageType;

#endif /* SHUtilsMacro_h */
