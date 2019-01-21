//
//  AppDelegate.m
//  SmartHome
//
//  Created by ZJ on 2017/4/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "AppDelegate.h"
#import "SHMessage.h"
//#import "MiPushSDK.h"
#import "SHDownloadManager.h"
#import "SHCameraManager.h"

// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
// 如果需要使用idfa功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
#import "SHSinglePreviewVC.h"

#import <Bugly/Bugly.h>
#import "MessageCenter.h"
#import "MessageInfo.h"
#import "SHCameraPreviewVC.h"
#import "SHHomeTableViewController.h"
#import "SHUserAccountInfoVC.h"
//#import "LogSet.h"
#import "type/ICatchLogLevel.h"
#import "XJLocalAssetHelper.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate,AllDownloadCompleteDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic) BOOL enableLog;
@property(nonatomic) FILE *appLogFile;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL loaded;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, weak) MBProgressHUD *progressHUD;
@property (nonatomic, weak) UIAlertController *networkAlertVC;

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
//    [self setupParameterWithOptions:launchOptions];
    [self jumpToCameraPreviewVCWithOptions:launchOptions];

	[self.window makeKeyAndVisible];
	
	//	[MiPushSDK registerMiPush:self type:0 connect:YES];
	
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
#if 0
    return mainStory.instantiateInitialViewController;
#else
    UIViewController *mainVC = mainStory.instantiateInitialViewController;
    [self setupMainVC:(UINavigationController *)mainVC options:launchOptions];
    SHUserAccountInfoVC *vc = [[SHUserAccountInfoVC alloc] init];
    vc.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext;
    
    ZJSlidingDrawerViewController *slidingDrawerVC = [ZJSlidingDrawerViewController slidingDrawerVCWithMainVC:mainVC leftMenuVC:vc slideScale:0.75];
    
    return slidingDrawerVC;
#endif
//    if (launchOptions == nil) {
//        return mainStory.instantiateInitialViewController;
//    } else {
//        _loaded = YES;
//
//        NSDictionary *pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//        SHLogInfo(SHLogTagAPP, @"pushNotificationKey: %@", pushNotificationKey);
//        NSDictionary *aps = [self parseNotification:pushNotificationKey];
//
//        NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];
//        if ([msgType isEqualToString:@"201"]) {
//            if ([self checkNotificationWhetherOverdue:aps]) {
//                return mainStory.instantiateInitialViewController;
//            }
//        }
//
//        return [mainStory instantiateViewControllerWithIdentifier:@"SinglePreviewID"];
//    }
}

- (void)setupMainVC:(UINavigationController *)mainVC options:(NSDictionary *)launchOptions {
    SHHomeTableViewController *homeVC = (SHHomeTableViewController *)mainVC.topViewController;
    homeVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext;
    
    if (launchOptions != nil) {
        NSDictionary *pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        NSDictionary *aps = [self parseNotification:pushNotificationKey];
        
        NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];
        if ([msgType isEqualToString:@"201"] && ![self checkNotificationWhetherOverdue:aps]) {
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
	int audioRate = [defaultSettings integerForKey:@"PreferenceSpecifier:audioRate"];
	
	//    self.enableLog = YES; // for test

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
        if ([msgType isEqualToString:@"201"] /*&& ![self checkNotificationWhetherOverdue:aps]*/) {
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
        
//        [self cleanBadgeNumber];
    } else {
//        [self showBadgeNumber];
    }
}

- (void)setupParameterWithOptions:(NSDictionary *)launchOptions {
#if 0
    UINavigationController *rootNavController = (UINavigationController *)self.window.rootViewController;
    SHHomeTableViewController *homeVC = (SHHomeTableViewController *)rootNavController.topViewController;
    homeVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext; //self.managedObjectContext;
#else
    ZJSlidingDrawerViewController *slidingVC = (ZJSlidingDrawerViewController *)self.window.rootViewController;
    UINavigationController *nav = (UINavigationController *)slidingVC.mainVC;
    SHHomeTableViewController *homeVC = (SHHomeTableViewController *)nav.topViewController;
    homeVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext; //self.managedObjectContext;
#endif
    
    if (launchOptions != nil) {
        _loaded = YES;
        NSDictionary *pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        SHLogInfo(SHLogTagAPP, @"pushNotificationKey: %@", pushNotificationKey);
        
        NSDictionary *aps = [self parseNotification:pushNotificationKey];
        
        NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];
        if ([msgType isEqualToString:@"201"] && ![self checkNotificationWhetherOverdue:aps]) {
            SHCameraPreviewVC *vc = [SHCameraPreviewVC cameraPreviewVC];
            
            vc.cameraUid = aps[@"devID"];//@"UXBDET7JWBP6S4Y5111A";
            vc.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext;
            vc.notification = aps; //@{@"msgType": @(201)};

            homeVC.notRequiredLogin = YES;
            [homeVC.navigationController pushViewController:vc animated:YES];
            
            [[[CoreDataHandler sharedCoreDataHander] fetchedCamera] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [[SHCameraManager sharedCameraManger] addSHCameraObject:obj];
            }];
        }
    }
    
#if 0
	if (launchOptions == nil) {
		UINavigationController *rootNavController = (UINavigationController *)self.window.rootViewController;
        SHCameraListTVC *homeVC = (SHCameraListTVC *)rootNavController.topViewController;
//        SHuserViewController *homeVC = (SHuserViewController*)rootNavController.topViewController;
        homeVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext; //self.managedObjectContext;
	} else {
		NSDictionary *pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		SHLogInfo(SHLogTagAPP, @"pushNotificationKey: %@", pushNotificationKey);
		
		NSDictionary *aps = [self parseNotification:pushNotificationKey];
		
        NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];
        if ([msgType isEqualToString:@"201"]) {
            if ([self checkNotificationWhetherOverdue:aps]) {
                UINavigationController *rootNavController = (UINavigationController *)self.window.rootViewController;
                SHCameraListTVC *homeVC = (SHCameraListTVC *)rootNavController.topViewController;
//                SHuserViewController *homeVC = (SHuserViewController*)rootNavController.topViewController;
                homeVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext; //self.managedObjectContext;
                return;
            }
        }
        
		NSString *uid = aps[@"devID"]; //@"UXBDET7JWBP6S4Y5111A";
		UINavigationController *rootNavController = (UINavigationController *)self.window.rootViewController;
        SHSinglePreviewVC *notifyVC = (SHSinglePreviewVC *)rootNavController;//(SHSinglePreviewVC *)rootNavController.topViewController;
        notifyVC.cameraUid = uid; //@"3AW1YKX6HWYG2M8X111A";
        notifyVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext; //self.managedObjectContext;
        notifyVC.notification = aps; //@{@"msgType":@201};
        
#if 0
		NSError *error = nil;
		if (![[self fetchedResultsController] performFetch:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
			abort();
#endif
		}
		[self fetchedSHCamera];
#else
        [[[CoreDataHandler sharedCoreDataHander] fetchedCamera] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[SHCameraManager sharedCameraManger] addSHCameraObject:obj];
        }];
#endif
	}
#endif
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
//    if ([[SHDownloadManager shareDownloadManger] isAllDownloadComplete] == YES) {
//        [self destroyAppResource];
//    } else {
////        if ([self.delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
////            SHLogInfo(SHLogTagAPP, @"Execute delegate method.");
////            [self.delegate applicationDidEnterBackground:nil];
////        }
////        [SHDownloadManager shareDownloadManger].allDownloadCompletedelegate = self;
//    }
//
//    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if ([defaults boolForKey:kEnterAPMode]) {
////        [defaults setBool:NO forKey:kEnterAPMode];
//    } else {
//        [self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
//    }
    [self removeGlobalObserver];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	SHLogTRACE();
//    [[SHPreviewManager sharedPreviewManager] cleanCellCache];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kEnterAPMode]) {
//        [defaults setBool:NO forKey:kEnterAPMode];
    } else {
        [self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
    }
	//	if ([self.delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
	//		SHLogInfo(SHLogTagAPP, @"Execute delegate method.");
	//		[self.delegate applicationDidEnterBackground:nil];
	//	} else {
	//		SHLogInfo(SHLogTagAPP, @"Execute default method.");
	//        dispatch_sync([[SHSDK sharedSHSDK] sdkQueue], ^{
	//            [[SHSDK sharedSHSDK] destroySHSDK];
	//        });
	//	}
	
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
	
	//    [self addNotificationWithTimeIntervalTrigger];
    [self addGlobalObserver];
}

- (void)addNotificationWithTimeIntervalTrigger
{
	UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
	content.title = @"时间戳定时推送";
	content.subtitle = @"subtitle";
	content.body = @"Copyright © 2016年 Hong. All rights reserved.";
	content.sound = [UNNotificationSound soundNamed:@"test.caf"];
	
	/*重点开始*/
	UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 repeats:NO];
	/*重点结束*/
	
	UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"TimeInterval" content:content trigger:trigger];
	
	[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
		NSLog(@"添加时间戳定时推送 : %@", error ? [NSString stringWithFormat:@"error : %@", error] : @"success");
	}];
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

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	if (_managedObjectContext != nil) {
		return _managedObjectContext;
	}
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator: coordinator];
	}
	return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
	if (_managedObjectModel != nil) {
		return _managedObjectModel;
	}
	//NSURL* modelURL=[[NSBundle mainBundle] URLForResource:@"Camera" withExtension:@"momd"];
	//_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	
	return _managedObjectModel;
}

/**
 Returns the URL to the application's documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
	if (_persistentStoreCoordinator != nil) {
		return _persistentStoreCoordinator;
	}
	
	// copy the default store (with a pre-populated data) into our Documents folder
	//
	NSString *documentsStorePath =
	[[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"SHCamera.sqlite"];
	SHLogInfo(SHLogTagAPP, @"sqlite's path: %@", documentsStorePath);
	
	// if the expected store doesn't exist, copy the default store
	if (![[NSFileManager defaultManager] fileExistsAtPath:documentsStorePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"SHCamera" ofType:@"sqlite"];
		if (defaultStorePath) {
			[[NSFileManager defaultManager] copyItemAtPath:defaultStorePath toPath:documentsStorePath error:NULL];
		}
	}
	
	_persistentStoreCoordinator =
	[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	
	// add the default store to our coordinator
	NSError *error;
	NSURL *defaultStoreURL = [NSURL fileURLWithPath:documentsStorePath];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												   configuration:nil
															 URL:defaultStoreURL
														 options:options
														   error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
		abort();
#endif
	}
	
	return _persistentStoreCoordinator;
}

#pragma mark - Core Data Saving support
- (void)saveContext {
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	if (managedObjectContext != nil) {
		NSError *error = nil;
		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
			abort();
#endif
		}
	}
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
#if 0
    MessageCenter* msgCenter = [[MessageCenter alloc] initWithName:message.devID andMSGDelegate:nil];
    MessageInfo* info = [[MessageInfo alloc] initWithMsgID:message.msgID andDevID:message.devID andDatetime:message.time andMsgType:message.msgType];
    [msgCenter addMessageWithMessageInfo:info];
#endif
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
//    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        BOOL hasConnected = NO;
		for(SHCameraObject *camera in [SHCameraManager sharedCameraManger].smarthomeCams) {
			if (camera.isConnect) {
//                hasConnected = YES;
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
//                    [camera disConnectWithSuccessBlock:nil failedBlock:nil];
                });
			}
		}
//        if (hasConnected) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:kEnterAPMode]) {
            [defaults setBool:NO forKey:kEnterAPMode];
        } else {
            exit(0);
        }
//        }
//    });
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
            
            //            [camera.sdk destroySHSDK];
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
	//    NSLog(@"This is device token: %@", deviceToken);
	NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
	SHLogInfo(SHLogTagAPP, @"This is device token: %@", token);
//    self.deviceToken = token;
    if (token != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:kDeviceToken];
    }
	//    UIAlertView *alertCtr = [[UIAlertView alloc] initWithTitle:@"Token is " message:token delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	//    [alertCtr show];
	
	/// Required - 注册 DeviceToken
	//    [JPUSHService registerDeviceToken:deviceToken];
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
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	
	// Required, iOS 7 Support
	//[JPUSHService handleRemoteNotification:userInfo];
    [self postNotification:userInfo];
    
	completionHandler(UIBackgroundFetchResultNewData);
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
#if 0
	if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
		//        NSLog(@"iOS10 前台收到远程通知:%@", [self logDic:userInfo]);
		SHLogInfo(SHLogTagAPP, @"iOS10 前台收到远程通知:%@", userInfo);
//        NSLog(@"收到的 alert: %@", [self parseNotification:userInfo]);
        
        [self postNotification:userInfo];
	} else {
		// 判断为本地通知
		SHLogInfo(SHLogTagAPP, @"iOS10 前台收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,userInfo);
	}
	
	completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"kPushTest"]) {
        if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            //        NSLog(@"iOS10 前台收到远程通知:%@", [self logDic:userInfo]);
            SHLogInfo(SHLogTagAPP, @"iOS10 前台收到远程通知:%@", userInfo);
            //        NSLog(@"收到的 alert: %@", [self parseNotification:userInfo]);
            
            [self postNotification:userInfo];
        } else {
            // 判断为本地通知
            SHLogInfo(SHLogTagAPP, @"iOS10 前台收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,userInfo);
        }
        
        completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    } else {
        [self notificationHandler:notification withCompletionHandler:completionHandler];
    }
#endif
    
//    [self showBadgeNumber];
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
        completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
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
		//        NSLog(@"iOS10 收到远程通知:%@", [self logDic:userInfo]);
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
    
//    [self cleanBadgeNumber];
}

- (NSDictionary *)parseNotification:(NSDictionary *)userInfo {
#if 0
    if (userInfo == nil) {
        return nil;
    }
    
	NSDictionary *aps = userInfo[@"aps"];
	NSString *alert = aps[@"alert"];
	NSDictionary *alertDict = [NSJSONSerialization JSONObjectWithData:[alert dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
//    NSLog(@"receive dict: %@", alertDict);
	
	return alertDict;
#else
    if (userInfo == nil) {
        return nil;
    }
    
    if ([userInfo.allKeys containsObject:@"handle"]) {
        if ([userInfo[@"handle"] intValue]) {
            NSDictionary *aps = userInfo[@"aps"];
            NSString *alert = aps[@"alert"];
            NSDictionary *alertDict = [NSJSONSerialization JSONObjectWithData:[alert dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
            
            return alertDict;
        } else {
            return userInfo;
        }
    } else {
        NSDictionary *aps = userInfo[@"aps"];
        NSString *alert = aps[@"alert"];
        NSDictionary *alertDict = [NSJSONSerialization JSONObjectWithData:[alert dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        
        return alertDict;
    }
#endif
}

- (void)presentSinglePreview:(NSDictionary *)userInfo {
#if 0
    UINavigationController *nav =(UINavigationController *)[[UIApplication sharedApplication] keyWindow].rootViewController;
    NSLog(@"nav: %@", nav);
    UIViewController *vc = nav.visibleViewController;
    NSLog(@"vc: %@", vc);
    
    NSDictionary *aps = [self parseNotification:userInfo];

    NSString *className = [NSString stringWithFormat:@"%@", [vc class]];
    if ([className isEqualToString:@"SHSinglePreviewVC"] || [className isEqualToString:@"SHCameraPreviewVC"]) {
//        SHSinglePreviewVC *singlePVVC = (SHSinglePreviewVC *)vc;
        SHCameraPreviewVC *singlePVVC = (SHCameraPreviewVC *)vc;
        NSString *uid = aps[@"devID"];

        if ([uid isEqualToString:singlePVVC.cameraUid]) {
            return;
        }
    }

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self stopAllPreview];
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [vc.navigationController presentViewController:[self getSinglePreview:aps] animated:YES completion:nil];
            [vc.navigationController pushViewController:[self getSinglePreview:aps] animated:YES];
        });
    });
#endif
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

//    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    UINavigationController *nav =(UINavigationController *)[mainStory instantiateViewControllerWithIdentifier:@"SinglePreviewID"];
//    SHSinglePreviewVC *singlePVVC = (SHSinglePreviewVC *)nav;//(SHSinglePreviewVC *)nav.topViewController;
    
    SHCameraPreviewVC *singlePVVC = [SHCameraPreviewVC cameraPreviewVC];
    
    singlePVVC.cameraUid = uid;
    singlePVVC.managedObjectContext = [CoreDataHandler sharedCoreDataHander].managedObjectContext; //self.managedObjectContext;
    singlePVVC.notification = aps;
    singlePVVC.foreground = YES;
    
    return singlePVVC;
}

- (void)networkDidReceiveMessage:(NSNotification *)notification {
	NSDictionary * userInfo = [notification userInfo];
	
	SHLogInfo(SHLogTagAPP, @"userInfo: %@", userInfo);
	//	NSString *content = [userInfo valueForKey:@"content"];
	//	NSDictionary *extras = [userInfo valueForKey:@"extras"];
	//	NSString *customizeField1 = [extras valueForKey:@"customizeField1"]; //服务端传递的Extras附加字段，key是自己定义的
	//	NSLog(@"receive jpush message is : %@",content);
	// FIXME: - 处理消息
	//    [self postNotification:userInfo];
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

#pragma mark - Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController {
	// Set up the fetched results controller if needed.
	if (_fetchedResultsController == nil) {
		// Create the fetch request for the entity.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		// Edit the entity name as appropriate.
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"SHCamera"
												  inManagedObjectContext:self.managedObjectContext];
		[fetchRequest setEntity:entity];
		
		// Edit the sort key as appropriate.
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createTime" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[fetchRequest setSortDescriptors:sortDescriptors];
		
		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
		NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
		
		aFetchedResultsController.delegate = self;
		self.fetchedResultsController = aFetchedResultsController;
	}
	return _fetchedResultsController;
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	//必须要写，否则数据无法存储
}

- (void)fetchedSHCamera {
	if (self.fetchedResultsController.sections.count > 0) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
		SHLogDebug(SHLogTagAPP, @"SHCamera num : %lu",(unsigned long)[sectionInfo numberOfObjects]);
		
		if([sectionInfo numberOfObjects] > 0) {
			
			for (int i=0; i<[sectionInfo numberOfObjects]; ++i) {
				//行数据
				NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
				SHCamera *camera = (SHCamera *)[self.fetchedResultsController objectAtIndexPath:indexPath];
				SHLogDebug(SHLogTagAPP, @"uid: %@ - name: %@ create time is %@", camera.cameraUid, camera.cameraName,camera.createTime);
				
				[[SHCameraManager sharedCameraManger] addSHCameraObject:camera];
			}
		}
	}
}

- (void)requestMicPermition{
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

#pragma mark - RecvNotificationBadge
- (void)showBadgeNumber {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSNumber *count  = [userDefault objectForKey:kRecvNotificationCount];
    [UIApplication sharedApplication].applicationIconBadgeNumber = count.integerValue;
}

- (void)cleanBadgeNumber {
    [[[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName] setObject:nil forKey:kRecvNotificationCount];
    
    [self showBadgeNumber];
}

#pragma mark - Configure Application SupportedInterfaceOrientations
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    if (self.isVideoPB) {
        return UIInterfaceOrientationMaskAll;
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
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
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

@end
