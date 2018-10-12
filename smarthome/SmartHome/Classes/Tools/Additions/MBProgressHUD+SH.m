//
//  MBProgressHUD+SH.m
//  SmartHome
//
//  Created by ZJ on 2017/4/14.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "MBProgressHUD+SH.h"

@implementation MBProgressHUD (SH)

+ (instancetype)progressHUDWithView:(UIView *)view {
    
    MBProgressHUD *progressHUD = [[self alloc] initWithView:view];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        progressHUD.minSize = CGSizeMake(60, 60);
    } else {
        progressHUD.minSize = CGSizeMake(120, 120);
    }
    progressHUD.minShowTime = 1;
    progressHUD.dimBackground = YES;
    progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]];
    
    [view addSubview:progressHUD];
    
    return progressHUD;
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time {
    if (message) {
        [self show:YES];
        self.labelText = message;
        self.mode = MBProgressHUDModeText;
        [self hide:YES afterDelay:time];
    } else {
        [self hide:YES];
    }
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.labelText = message;
    self.mode = MBProgressHUDModeIndeterminate;
    [self show:YES];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        [self show:YES];
        self.labelText = message;
        self.detailsLabelText = nil;
        self.mode = MBProgressHUDModeCustomView;
        [self hide:YES afterDelay:1.0];
    } else {
        [self hide:YES];
    }
}

- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              mode:(MBProgressHUDMode)mode {
    if (self.alpha == 0 ) {
        self.labelText = message;
        self.detailsLabelText = dMessage;
        self.mode = mode;
        [self show:YES];
    }
}

- (void)updateProgressHUDWithMessage:(NSString *)message
                      detailsMessage:(NSString *)dMessage
                             percent:(NSUInteger)curPercent {
    if (message) {
        self.labelText = message;
    }
    if (dMessage) {
        self.progress = curPercent / 100.0;
        self.detailsLabelText = dMessage;
    }
}

- (void)hideProgressHUD:(BOOL)animated {
    [self hide:animated];
}

@end
