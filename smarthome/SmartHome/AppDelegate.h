//
//  AppDelegate.h
//  SmartHome
//
//  Created by ZJ on 2017/4/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppDelegateDelegate <NSObject>
@optional
- (void)applicationDidEnterBackground:(UIApplication *)application NS_AVAILABLE_IOS(4_0);
- (void)applicationDidBecomeActive:(UIApplication *)application NS_AVAILABLE_IOS(4_0);
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, weak) id <AppDelegateDelegate> delegate;
//@property (nonatomic, copy) NSString *deviceToken;

@end

