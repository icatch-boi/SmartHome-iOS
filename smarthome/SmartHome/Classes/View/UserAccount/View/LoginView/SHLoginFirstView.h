// SHLoginFirstView.h

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by zj on 2018/5/19 上午9:36.
    

#import <UIKit/UIKit.h>

@class SHLoginFirstView;
@protocol SHLoginFirstViewDelegate <NSObject>

- (void)signupAccount:(SHLoginFirstView *)view;
- (void)signinAccount:(SHLoginFirstView *)view;

@end

@interface SHLoginFirstView : UIView

@property (nonatomic, weak) id<SHLoginFirstViewDelegate> delegate;

+ (instancetype)loginFirstView;

@end
