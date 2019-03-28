//
//  AppDelegate.m
//  SmartHome
//
//  Created by ZJ on 2017/4/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "AppDelegate.h"
#import "SHMessage.h"

#import "SHDownloadManager.h"
#import "SHCameraManager.h"

// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

#import "SHSinglePreviewVC.h"
#import "SHVideoPlaybackVC.h"

#import <Bugly/Bugly.h>
#import "SHCameraPreviewVC.h"
#import "SHHomeTableViewController.h"
#import "SHUserAccountInfoVC.h"

#import "type/ICatchLogLevel.h"
#import "XJLocalAssetHelper.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "SHDeviceUpgradeVC.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate,AllDownloadCompleteDelegate>

@property(nonatomic) BOOL enableLog;
@property(nonatomic) FILE *appLogFile;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL loaded;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, weak) MBProgressHUD *progressHUD;
@property (nonatomic, weak) UIAlertController *networkAlertVC;
@property (nonatomic, weak) UIAlertController *lowBatteryAlertVC;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
    BuglyConfig *config = [[BuglyConfig alloc] init];
    config.debugMode = YES;
    [Bugly startWithAppId:nil config:config];
	[self registerDefaultsFromSettingsBundle];
	
	[self setupAppLog];
	
	self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	self.window.rootViewController = [self getAppRootVCWithOptions:launchOptions];

    [self jumpToCameraPreviewVCWithOptions:launchOptions];

	[self.window makeKeyAndVisible];
		
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	
	[self registerNotification:application];
	[self requestMicPermition];
    
    [XJLocalAssetHelper sharedLocalAssetHelper];
    [SHSDK loadTutkLibrary];

    [self addNetworkStatusObserver];

	return YES;
}

- (void)showAppVersionInfoAndRunDate {
    NSDate *date = [NSDate date];

    NSLog(@"====================== App run starting =======================");
    NSLog(@"###### App Version: %@", APP_VERSION);
    NSLog(@"###### Build: %@", APP_BUILDNUMBER);
    
    NSLog(@"---------------------------------------------------------------");
    
    SDKInfo *sdkInfo = SDKInfo::getInstance();
    string sdkVString = sdkInfo->getSDKVersion();
    NSLog(@"###### SDK Version: %s", sdkVString.c_str());

    NSLog(@"---------------------------------------------------------------");

    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSLog(@"###### Run Date: %@", [dateformatter stringFromDate:date]);
    NSLog(@"###### Device info: %@", [SHTool deviceInfo]);
    NSLog(@"###### Locale Language Code: %@（%@）", [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode], [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0]);
    NSLog(@"===============================================================");
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
}

- (UIViewController *)getAppRootVCWithOptions:(NSDictionary *)launchOptions {
	UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"XJMain" bundle:nil];

    UIViewController *mainVC = mainStory.instantiateInitialViewController;
    [self setupMainVC:(UINavigationController *)mainVC options:launchOptions];
    SHUserAccountInfoVC *vc = [[SHUserAccountInfoVC alloc] init];
    vc.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext;
    
    ZJSlidingDrawerViewController *slidingDrawerVC = [ZJSlidingDrawerViewController slidingDrawerVCWithMainVC:mainVC leftMenuVC:vc slideScale:0.75];
    
    return slidingDrawerVC;
}

- (void)setupMainVC:(UINavigationController *)mainVC options:(NSDictionary *)launchOptions {
    SHHomeTableViewController *homeVC = (SHHomeTableViewController *)mainVC.topViewController;
    homeVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext;
    
    if (launchOptions != nil) {
        NSDictionary *pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        NSDictionary *aps = [self parseNotification:pushNotificationKey];
        
        NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];
        if (([msgType isEqualToString:@"201"] && ![self checkNotificationWhetherOverdue:aps]) || [msgType isEqualToString:@"202"]) {
            homeVC.notRequiredLogin = YES;
        }
    }
}

- (BOOL)checkNotificationWhetherOverdue:(NSDictionary *)aps {
    NSString *time = aps[@"time"];
    
    NSDate *startDate = [time convertToDateWithFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *endDate = [NSDate date];
    
    NSTimeInterval interval = [endDate timeIntervalSinceDate:startDate];
    
    BOOL overdue = NO;
    
    if (interval > 120) {
        overdue = YES;
    }
    
    return overdue;
}

- (void)setupAppLog {
	NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
	self.enableLog = [defaultSettings boolForKey:@"PreferenceSpecifier:SHAppLog"];
	
	if (_enableLog) {
		[self startLogToFile];
	} else {
		[self cleanLogs];
        
#if (SDK_DEBUG==1)
#if 1
        Log* log = Log::getInstance();
        log->setSystemLogOutput( true );
        log->setPtpLog(true);
        log->setRtpLog(false);
        log->setPtpLogLevel(LOG_LEVEL_INFO);
        log->setRtpLogLevel(LOG_LEVEL_INFO);
        log->start();
#else
        LogSet *log = LogSet::instance();
        log->setPath(LOG_TYPE_SDK, ".");
        log->setLevel(LOG_TYPE_SDK, LOG_LEVEL_INFO);
        log->setEnable(LOG_TYPE_SDK, true);
        log->setOutToFile(LOG_TYPE_SDK, false);
        log->setOutToScreen(LOG_TYPE_SDK, true);
        log->logStart();
#endif
#endif
	}
    
    [self showAppVersionInfoAndRunDate];
}

- (void)jumpToCameraPreviewVCWithOptions:(NSDictionary *)launchOptions {
    if (launchOptions != nil) {
        _loaded = YES;
        NSDictionary *pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        SHLogInfo(SHLogTagAPP, @"pushNotificationKey: %@", pushNotificationKey);
        
        NSDictionary *aps = [self parseNotification:pushNotificationKey];
        
        NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];
        if (([msgType isEqualToString:@"201"] && ![self checkNotificationWhetherOverdue:aps]) || [msgType isEqualToString:@"202"]) {
            SHCameraPreviewVC *vc = [SHCameraPreviewVC cameraPreviewVC];
        
            vc.cameraUid = aps[@"devID"]; //@"CVL32D1VV9BJ4XLN111A";
            vc.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext;
            vc.notification = aps; //@{@"msgType": @(201)};
        
            [[[CoreDataHandler sharedCoreDataHander] fetchedCamera] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [[SHCameraManager sharedCameraManger] addSHCameraObject:obj];
            }];
        
            ZJSlidingDrawerViewController *slidingVC = (ZJSlidingDrawerViewController *)self.window.rootViewController;
            UINavigationController *mainVC = (UINavigationController *)slidingVC.mainVC;
        
            [mainVC pushViewController:vc animated:YES];
        }
    } else {
    }
}

- (void)registerNotification:(UIApplication *)application
{
	if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
		// iOS10特有
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		center.delegate = self;
		[center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
			if (granted) {
				// 点击允许
				SHLogInfo(SHLogTagAPP, @"注册成功");
				[center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
					SHLogInfo(SHLogTagAPP, @"%@", settings);
				}];
			} else {
				// 点击不允许
				SHLogError(SHLogTagAPP, @"注册失败");
			}
			
		}];
	} else if ([[UIDevice currentDevice].systemVersion floatValue] >8.0){
		// iOS8 - iOS10
		[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge categories:nil]];
	} else if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
		// iOS8系统以下
		[application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
	}
	
	// 注册获得device Token
	[[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    SHLogTRACE();
    
    [self removeGlobalObserver];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	SHLogTRACE();
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kEnterAPMode]) {
//        [defaults setBool:NO forKey:kEnterAPMode];
    } else {
        [self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
    }
	
    if([[SHDownloadManager shareDownloadManger] isAllDownloadComplete] == YES){
        //exit app
        [self exitApp];
    }else{
        if ([self.delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            SHLogInfo(SHLogTagAPP, @"Execute delegate method.");
            [self.delegate applicationDidEnterBackground:nil];
        }
        //wait for download completed and exit app
        [SHDownloadManager shareDownloadManger].allDownloadCompletedelegate = self;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	SHLogTRACE();
    [application setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	if ([self.delegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
		[self.delegate applicationDidBecomeActive:nil];
	}
	
    [self addGlobalObserver];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	SHLogTRACE();
	
	if (_enableLog) {
		[self stopLog];
	}
    
    [SHSDK unloadTutkLibrary];
}

#pragma mark - SHLogInfo Operate
- (void)startLogToFile
{
	SHLogTRACE();
	
	// Get the document directory
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	// Name the log folder & file
	NSDate *date = [NSDate date];
	NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
	[dateformatter setDateFormat:@"yyyyMMdd-HHmmss"];
	NSString *name = [dateformatter stringFromDate:date];
	NSString *appLogFileName = [NSString stringWithFormat:@"SHAPP-%@.log", name];
	// Create the log folder
	NSString *logDirectory = [documentsDirectory stringByAppendingPathComponent:name];
	[[NSFileManager defaultManager] createDirectoryAtPath:logDirectory withIntermediateDirectories:NO attributes:nil error:nil];
	// Create(Open) the log file
	NSString *appLogFilePath = [logDirectory stringByAppendingPathComponent:appLogFileName];
	self.appLogFile = freopen([appLogFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
	
	// LogSDK
	//    [[SHSDK sharedSHSDK] enableLogSdkAtDiretctory:logDirectory enable:YES];
	[SHTool enableLogSdkAtDiretctory:logDirectory enable:YES];
}

- (void)stopLog
{
	SHLogTRACE();
	fclose(_appLogFile);
}

- (void)cleanLogs
{
	SHLogTRACE();
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
	NSString *logFilePath = nil;
	for (NSString *fileName in  documentsDirectoryContents) {
		if (![fileName isEqualToString:@"SHCamera.sqlite"] && ![fileName isEqualToString:@"SHCamera.sqlite-shm"] && ![fileName isEqualToString:@"SHCamera.sqlite-wal"] && ![fileName isEqualToString:@"SmartHome-Medias"] && ![fileName hasSuffix:@".db"] && ![fileName hasSuffix:@".plist"]) {
			
			logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
			[[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
		}
		
	}
}

// retrieve the default setting values
- (void)registerDefaultsFromSettingsBundle {
	NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
	if(!settingsBundle) {
		SHLogError(SHLogTagAPP, @"Could not find Settings.bundle");
		return;
	}
	
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
	NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
	
	NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
	for(NSDictionary *prefSpecification in preferences) {
		NSString *key = [prefSpecification objectForKey:@"Key"];
		if(key) {
			[defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
		}
	}
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

#pragma mark Local And Push Notification
- (void)postNotification:(NSDictionary *)userInfo {
    NSDictionary *aps = userInfo[@"aps"];
    NSString *alert = aps[@"alert"];
    @try {
        id json = [NSJSONSerialization JSONObjectWithData:[alert dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        
        SHMessage *message = [SHMessage messageWithDict:json];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPushMessageNotification object:message];
    } @catch (NSException *exception) {
        SHLogError(SHLogTagAPP, @"JSON parse happen exception: %@", exception);
    } @finally {
        
    }
}

- (void)onAllDownloadComplete{
	//if app is in backgroud,disconnect all cameras
	UIApplicationState state = [UIApplication sharedApplication].applicationState;
	if(state == UIApplicationStateBackground){
		[self exitApp];
	}
}

- (void)exitApp {
	//find cameras to disconnect and update ui

    for(SHCameraObject *camera in [SHCameraManager sharedCameraManger].smarthomeCams) {
        if (camera.isConnect) {
            [camera.sdk disableTutk];
            dispatch_sync(camera.sdk.sdkQueue, ^{
                if ((camera.controler.actCtrl.isRecord)) {
                    [camera.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
                }
                
                if (camera.streamOper.PVRun) {
                    [camera.streamOper stopMediaStreamWithComplete:nil];
                }
                
                [camera.controler.pbCtrl stopWithCamera:camera];

                [camera.sdk destroySHSDK];
            });
        }
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kEnterAPMode]) {
        [defaults setBool:NO forKey:kEnterAPMode];
    } else {
        exit(0);
    }
}

- (void)destroyAppResource {
    SHLogInfo(SHLogTagAPP, @"destroyAppResource start.");
    BOOL hasConnected = NO;
    
    NSArray *tempArray = [SHCameraManager sharedCameraManger].smarthomeCams;
    for (SHCameraObject *camera in tempArray) {
        if (camera.isConnect) {
            camera.isConnect = NO;
            [camera.sdk disableTutk];
            hasConnected = YES;
            
            if (camera.controler.actCtrl.isRecord) {
                [camera.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
            }
            
            if (camera.streamOper.PVRun) {
                [camera.streamOper stopMediaStreamWithComplete:nil];
            }
            
            [camera.controler.pbCtrl stopWithCamera:camera];
            
            [camera disConnectWithSuccessBlock:nil failedBlock:nil];
        }
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kEnterAPMode] && hasConnected) {
        exit(0);
    }
    
    SHLogInfo(SHLogTagAPP, @"destroyAppResource end.");
}

void uncaughtExceptionHandler(NSException *exception){
	SHLogInfo(SHLogTagAPP, @"Crash:%@",exception);
	SHLogInfo(SHLogTagAPP, @"Stack trace:%@",[exception callStackSymbols]);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
	SHLogInfo(SHLogTagAPP, @"This is device token: %@", token);

    if (token != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:kDeviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	//Optional
	SHLogInfo(SHLogTagAPP, @"did Fail To Register For Remote Notifications With Error: %@", error);
}

#pragma mark - NotificationDelegate
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
	
	SHLogInfo(SHLogTagAPP, @"iOS6及以下系统，收到通知:%@", [self logDic:userInfo]);
    [self postNotification:userInfo];
    [self notificationHandleWithInfo:userInfo withCompletionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	
	// Required, iOS 7 Support
    [self postNotification:userInfo];
    
	completionHandler(UIBackgroundFetchResultNewData);
    [self notificationHandleWithInfo:userInfo withCompletionHandler:nil];
}

// iOS 10收到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{

	NSDictionary * userInfo = notification.request.content.userInfo;
	
	UNNotificationRequest *request = notification.request; // 收到推送的请求
	UNNotificationContent *content = request.content; // 收到推送的消息内容
	NSNumber *badge = content.badge;  // 推送消息的角标
	NSString *body = content.body;    // 推送消息体
	UNNotificationSound *sound = content.sound;  // 推送消息的声音
	NSString *subtitle = content.subtitle;  // 推送消息的副标题
	NSString *title = content.title;  // 推送消息的标题

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"kPushTest"]) {
        if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            SHLogInfo(SHLogTagAPP, @"iOS10 前台收到远程通知:%@", userInfo);
            
            [self postNotification:userInfo];
        } else {
            // 判断为本地通知
            SHLogInfo(SHLogTagAPP, @"iOS10 前台收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,userInfo);
        }
        
        [self notificationHandleWithInfo:userInfo withCompletionHandler:completionHandler];
//        completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    } else {
        [self notificationHandler:notification withCompletionHandler:completionHandler];
    }
}

- (void)notificationHandleWithInfo:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    NSDictionary *aps = [self parseNotification:userInfo];
    
    int msgType = [aps[@"msgType"] intValue];
    switch (msgType) {
        case 106:
            [self upgradingWithCameraUID:aps[@"devID"]] ? [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadUpgradePackageSuccessNotification object:nil] : void();
            break;
        case 107:
        case 109:
            [self upgradingWithCameraUID:aps[@"devID"]] ? [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceUpgradeFailedNotification object:nil] : void();
            break;
            
        case 108:
            [self upgradingWithCameraUID:aps[@"devID"]] ? [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceUpgradeSuccessNotification object:nil] : void();
            break;
            
        case 102:
            [self lowBatteryHandleWithUID:aps[@"devID"] disconnect:NO];
            break;
            
        case 110:
            [self lowBatteryHandleWithUID:aps[@"devID"] disconnect:YES];
            break;
            
        default:
            break;
    }
    
    if (msgType != 106) {
        if (completionHandler == nil) {
            return;
        }
        
        completionHandler(UNNotificationPresentationOptionAlert/*|UNNotificationPresentationOptionBadge*/); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    }
}

- (BOOL)upgradingWithCameraUID:(NSString *)uid {
    BOOL upgrade = NO;
    
    if (uid == nil || uid.length <= 0) {
        return upgrade;
    }
    
    UIViewController *vc = [SHTool appVisibleViewController];
    if ([vc isMemberOfClass:[SHDeviceUpgradeVC class]]) {
        SHDeviceUpgradeVC *temp = (SHDeviceUpgradeVC *)vc;
        if ([temp.camObj.camera.cameraUid isEqualToString:uid]) {
            upgrade = YES;
        }
    }
    
    return upgrade;
}

- (void)notificationHandler:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSDictionary * userInfo = notification.request.content.userInfo;

        [self addReceiveMessage:userInfo];
    } else {
        // 判断为本地通知
        SHLogInfo(SHLogTagAPP, @"iOS10 前台收到本地通知");
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kQuiesce"]) {
        completionHandler(UNNotificationPresentationOptionAlert/*|UNNotificationPresentationOptionBadge*/); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    }
}

// 通知的点击事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
	
	NSDictionary * userInfo = response.notification.request.content.userInfo;
	UNNotificationRequest *request = response.notification.request; // 收到推送的请求
	UNNotificationContent *content = request.content; // 收到推送的消息内容
	
	NSNumber *badge = content.badge;  // 推送消息的角标
	NSString *body = content.body;    // 推送消息体
	UNNotificationSound *sound = content.sound;  // 推送消息的声音
	NSString *subtitle = content.subtitle;  // 推送消息的副标题
	NSString *title = content.title;  // 推送消息的标题
	
	if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
		SHLogInfo(SHLogTagAPP, @"iOS10 前台收到远程通知:%@", userInfo);
	} else {
		// 判断为本地通知
		SHLogInfo(SHLogTagAPP, @"iOS10 收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,userInfo);
	}
	
	// Warning: UNUserNotificationCenter delegate received call to -userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: but the completion handler was never called.
	completionHandler();  // 系统要求执行这个方法
    
    if (_loaded == NO) {
        if (![self checkNotificationWhetherOverdue:[self parseNotification:userInfo]]) {
            [self presentSinglePreview:userInfo];
        }
    } else {
        _loaded = NO;
    }
}

- (NSDictionary *)parseNotification:(NSDictionary *)userInfo {
    if (userInfo == nil) {
        return nil;
    }
    
    if ([userInfo.allKeys containsObject:@"devID"]) {
        return userInfo;
    } else {
        NSDictionary *aps = userInfo[@"aps"];
        NSString *alert = aps[@"alert"];
        NSDictionary *alertDict = [NSJSONSerialization JSONObjectWithData:[alert dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        
        return alertDict;
    }
}

- (void)presentSinglePreview:(NSDictionary *)userInfo {
    UINavigationController *nav = (UINavigationController *)[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC;
    UIViewController *vc = nav.visibleViewController;
    SHLogInfo(SHLogTagAPP, @"vc: %@", vc);
    
    NSDictionary *aps = [self parseNotification:userInfo];
    NSString *uid = aps[@"devID"];

    NSString *className = [NSString stringWithFormat:@"%@", [vc class]];
    if ([className isEqualToString:@"SHCameraPreviewVC"]) {
        SHCameraPreviewVC *previewVC = (SHCameraPreviewVC *)vc;
        
        if ([uid isEqualToString:previewVC.cameraUid]) {
            return;
        }
    } else if ([className isEqualToString:@"SHSinglePreviewVC"]) {
        SHSinglePreviewVC *singlePVVC = (SHSinglePreviewVC *)vc;
        
        if ([uid isEqualToString:singlePVVC.cameraUid]) {
            return;
        }
    }
    
    if ([className isEqualToString:@"SHVideoPlaybackVC"]) {
        SHVideoPlaybackVC *pbVC = (SHVideoPlaybackVC *)vc;
        [pbVC stopVideoPb];
        
        [SHTool configureAppThemeWithController:vc.navigationController];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self stopAllPreview];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc.navigationController pushViewController:[self getSinglePreview:aps] animated:YES];
        });
    });
}

- (void)stopAllPreview {
    NSArray *cameras =  [SHCameraManager sharedCameraManger].smarthomeCams;
    
    for(SHCameraObject *camera in cameras) {
        if (camera.isConnect) {
            if (camera.streamOper.PVRun) {
                [camera.streamOper stopMediaStreamWithComplete:nil];
            }
            
            [camera.controler.pbCtrl stopWithCamera:camera];
        }
    }
}

- (UIViewController *)getSinglePreview:(NSDictionary *)aps {
    NSString *uid = aps[@"devID"];
    
    SHCameraPreviewVC *singlePVVC = [SHCameraPreviewVC cameraPreviewVC];
    
    singlePVVC.cameraUid = uid;
    singlePVVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext;
    singlePVVC.notification = aps;
    singlePVVC.foreground = YES;
    
    return singlePVVC;
}

// log NSSet with UTF8
// if not ,log will be \Uxxx
- (NSString *)logDic:(NSDictionary *)dic {
	if (![dic count]) {
		return nil;
	}
	NSString *tempStr1 =
	[[dic description] stringByReplacingOccurrencesOfString:@"\\u"
												 withString:@"\\U"];
	NSString *tempStr2 =
	[tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	NSString *tempStr3 =
	[[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
	NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
	NSString *str =
	[NSPropertyListSerialization propertyListFromData:tempData
									 mutabilityOption:NSPropertyListImmutable
											   format:NULL
									 errorDescription:NULL];
	return str;
}

- (void)requestMicPermition {
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
		AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
		switch (permissionStatus) {
			case AVAudioSessionRecordPermissionUndetermined:{
				SHLogInfo(SHLogTagAPP, @"第一次调用，是否允许麦克风弹框");
				[[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
					// CALL YOUR METHOD HERE - as this assumes being called only once from user interacting with permission alert!
					if (granted) {
						// Microphone enabled code
					}
					else {
						// Microphone disabled code
					}
				}];
				break;
			}
			case AVAudioSessionRecordPermissionDenied:
				// direct to settings...
				SHLogWarn(SHLogTagAPP, @"已经拒绝麦克风弹框");
				break;
			case AVAudioSessionRecordPermissionGranted:
				SHLogInfo(SHLogTagAPP, @"已经允许麦克风弹框");
				// mic access ok...
				break;
			default:
				// this should not happen.. maybe throw an exception.
				break;
		}
		if(permissionStatus == AVAudioSessionRecordPermissionUndetermined)
			return;
	}
}

#pragma mark - ICatch Push Test
- (void)addReceiveMessage:(NSDictionary *)userInfo {
    NSDictionary *notification = [self parseNotification:userInfo];
    
    NSDate *date = [NSDate date];
    NSTimeInterval client = date.timeIntervalSince1970;
    
    NSString *msgID = notification[@"msgID"];
    NSString *tmdbg = notification[@"tmdbg"];
    if (msgID == nil || tmdbg == nil) {
        SHLogInfo(SHLogTagAPP, @"msgID or tmdbg is nil, msgID: %@, tmdbg: %@", msgID, tmdbg);
        return;
    }
    
    NSDictionary *dict = @{
                           @"msgID": msgID,
                           @"device": tmdbg,
                           @"client": @(client).stringValue,
                           };
    
    dict ? [self.messages addObject:dict] : void();
}

- (NSMutableArray *)messages {
    if (_messages == nil) {
        _messages = [NSMutableArray array];
    }
    
    return _messages;
}

- (void)cleanMessageCache {
    [self.messages removeAllObjects];
}

#pragma mark - Configure Application SupportedInterfaceOrientations
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    if (self.isVideoPB) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else if (self.isFullScreenPV) {
        return UIInterfaceOrientationMaskLandscape;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - DownloadCompleteHandle
- (void)addGlobalObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(singleDownloadCompleteHandle:) name:kSingleDownloadCompleteNotification object:nil];
}

- (void)removeGlobalObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)singleDownloadCompleteHandle:(NSNotification *)nc {
    NSDictionary *tempDict = nc.userInfo;
    
    NSString *msg = [SHTool createDownloadComplete:tempDict];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *nav = (UINavigationController *)[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC;
        UIViewController *vc = nav.visibleViewController;
        if ([NSStringFromClass([vc class]) isEqualToString:@"SHHomeTableViewController"]) {
            SHLogInfo(SHLogTagAPP, @"Current home page, not tips.");
            return;
        }
        
        [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"Tips", nil) showTime:kShowDownloadCompleteNoteTime * 0.6];
        _progressHUD.detailsLabelText = msg;
    });
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (_progressHUD != nil) {
        _progressHUD = nil;
    }
    
    _progressHUD = [MBProgressHUD progressHUDWithView:self.window];
    
    return _progressHUD;
}

#pragma mark - Monitor Network Status
- (void)addNetworkStatusObserver {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSString *netStatus = nil;
        
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                netStatus = @"Unknown";
                
                break;
            case AFNetworkReachabilityStatusNotReachable:
                netStatus = @"NotReachable";
                
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                netStatus = @"ReachableViaWWAN";
                [self dismissNetworkAlertVC];
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
                netStatus = @"ReachableViaWiFi";
                [self dismissNetworkAlertVC];
                break;
        }
        
        if (status == AFNetworkReachabilityStatusNotReachable) {
            [self showNetworkNotReachableAlertView];
        }
        
        SHLogInfo(SHLogTagAPP, @"Current network status: %@", netStatus);
    }];
}

- (void)showNetworkNotReachableAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kNetworkBad", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        STRONG_SELF(self);
        
        [self dismissNetworkAlertVC];
    }]];
    
    UINavigationController *nav = (UINavigationController *)[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC;
    UIViewController *vc = nav.visibleViewController;
    [vc presentViewController:alertVC animated:YES completion:nil];
    self.networkAlertVC = alertVC;
}

- (void)dismissNetworkAlertVC {
    if (self.networkAlertVC != nil) {
        [self.networkAlertVC dismissViewControllerAnimated:YES completion:^{
            self.networkAlertVC = nil;
        }];
    }
}

#pragma mark - LowBattery Handle
- (void)lowBatteryHandleWithUID:(NSString *)uid disconnect:(BOOL)disconnect {
    UINavigationController *nav = (UINavigationController *)[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC;
    UIViewController *vc = nav.visibleViewController;
    if ([NSStringFromClass([vc class]) isEqualToString:@"SHHomeTableViewController"]) {
        SHLogInfo(SHLogTagAPP, @"Current home page, not tips.");
        [self dismissLowBatteryAlertVC];
        return;
    }
    
    if (uid == nil) {
        SHLogError(SHLogTagAPP, @"Camera uid is nil.");
        return;
    }
    
    SHCameraObject *camObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:uid];
    if (camObj == nil) {
        SHLogWarn(SHLogTagAPP, @"camera object is nil.");
        return;
    }
    
    if (camObj.isConnect) {
        [self showLowBatteryAlertViewWithCameraObj:camObj disconnect:disconnect];
    } else {
        if ([NSStringFromClass([vc class]) isEqualToString:@"SHCameraPreviewVC"]) {
            SHCameraPreviewVC *temp = (SHCameraPreviewVC *)vc;
            if ([temp.cameraUid isEqualToString:uid]) {
                [self showLowBatteryAlertViewWithCameraObj:camObj disconnect:disconnect];
                return;
            }
        }
        
        [self dismissLowBatteryAlertVC];
    }
}

- (void)showLowBatteryAlertViewWithCameraObj:(SHCameraObject *)camObj disconnect:(BOOL)disconnect {
    if (self.lowBatteryAlertVC != nil) {
        return;
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"kLowBatteryAlert", nil), camObj.camera.cameraName, NSLocalizedString(@"ALERT_LOW_BATTERY", nil)];
    if (disconnect) {
        message = [NSString stringWithFormat:NSLocalizedString(@"kLowBatteryAlert", nil), camObj.camera.cameraName, NSLocalizedString(@"kLowBatteryNotification", nil)];
        [camObj.sdk disableTutk];
    }
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (disconnect) {
                [SHTool backToRootViewController];
                [camObj disConnectWithSuccessBlock:nil failedBlock:nil];
            }
        });
    }]];
    
    UINavigationController *nav = (UINavigationController *)[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC;
    UIViewController *vc = nav.visibleViewController;
    [vc presentViewController:alertVC animated:YES completion:nil];
    
    self.lowBatteryAlertVC = alertVC;
}

- (void)dismissLowBatteryAlertVC {
    if (self.lowBatteryAlertVC != nil) {
        [self.lowBatteryAlertVC dismissViewControllerAnimated:YES completion:^{
            self.lowBatteryAlertVC = nil;
        }];
    }
}

@end
