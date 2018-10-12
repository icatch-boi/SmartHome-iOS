//
//  GCDiscreetNotificationView+Addition.h
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "GCDiscreetNotificationView.h"

@interface GCDiscreetNotificationView (Addition)

- (void)showGCDNoteWithMessage:(NSString *)message
                  withAnimated:(BOOL)animated
                    withAcvity:(BOOL)activity;

- (void)showGCDNoteWithMessage:(NSString *)message
                       andTime:(NSTimeInterval) timeInterval
                    withAcvity:(BOOL)activity;

- (void)hideGCDiscreetNoteView:(BOOL)animated;

@end
