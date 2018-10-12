//
//  GCDiscreetNotificationView+Addition.m
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "GCDiscreetNotificationView+Addition.h"

@implementation GCDiscreetNotificationView (Addition)

- (void)showGCDNoteWithMessage:(NSString *)message
                  withAnimated:(BOOL)animated
                    withAcvity:(BOOL)activity {
    [self setTextLabel:message];
    [self setShowActivity:activity];
    [self show:animated];
}

- (void)showGCDNoteWithMessage:(NSString *)message
                       andTime:(NSTimeInterval) timeInterval
                    withAcvity:(BOOL)activity {
    [self setTextLabel:message];
    [self setShowActivity:activity];
    [self showAndDismissAfter:timeInterval];
}

- (void)hideGCDiscreetNoteView:(BOOL)animated {
    [self hide:animated];
}

@end
