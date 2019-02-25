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

@property (nonatomic, weak) id <AppDelegateDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableArray *messages;
@property (nonatomic, assign) BOOL isVideoPB;
@property (nonatomic, assign) BOOL isFullScreenPV;

- (void)cleanMessageCache;

@end

