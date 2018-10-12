//
//  ZJSlidingDrawerViewController.h
//  SlidingDrawer
//
//  Created by zj on 2018/5/13.
//  Copyright © 2018年 zj. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width

@interface ZJSlidingDrawerViewController : UIViewController

@property (nonatomic, strong, readonly) UIViewController *mainVC;

+ (instancetype)sharedSlidingDrawerVC;
+ (instancetype)slidingDrawerVCWithMainVC:(UIViewController *)mainVC leftMenuVC:(UIViewController *)leftMenuVC slideScale:(CGFloat)slideScale;

- (void)openLeftMenu;
- (void)closeLeftMenu;
- (void)pushViewController:(UIViewController *)destVC;
- (void)popViewController;

- (void)signupAccountHandleWithEmail:(NSString *)email isResetPWD:(BOOL)reset;
- (void)signinAccountHandle;
- (void)closeLoginFirstView;

@end
