//
//  MBProgressHUD+SH.h
//  SmartHome
//
//  Created by ZJ on 2017/4/14.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (SH)

+ (instancetype)progressHUDWithView:(UIView *)view;

- (void)showProgressHUDWithMessage:(NSString *)message;
- (void)showProgressHUDNotice:(NSString *)message showTime:(NSTimeInterval)time;
- (void)showProgressHUDCompleteMessage:(NSString *)message;
- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              mode:(MBProgressHUDMode)mode;
- (void)updateProgressHUDWithMessage:(NSString *)message
                      detailsMessage:(NSString *)dMessage
                             percent:(NSUInteger)curPercent;
- (void)hideProgressHUD:(BOOL)animated;

@end
