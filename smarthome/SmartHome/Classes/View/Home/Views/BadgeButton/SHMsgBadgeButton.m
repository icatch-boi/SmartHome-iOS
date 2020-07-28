// SHMsgBadgeButton.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2019/8/21 10:58 AM.
    

#import "SHMsgBadgeButton.h"

@implementation SHMsgBadgeButton

- (void)setSubFrame {
    [super setSubFrame];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.imageView.image) {
            CGPoint center = CGPointMake(CGRectGetMaxX(self.imageView.frame) - CGRectGetWidth(self.badgeLab.bounds), self.imageView.frame.origin.y + CGRectGetHeight(self.badgeLab.bounds));
            self.badgeLab.center = center;
        } else {
            CGPoint center = CGPointMake(self.bounds.size.width, self.bounds.origin.y);
            self.badgeLab.center = center;
        }
    });
}

@end
