// SHOperationView.h

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
 
 // Created by zj on 2019/10/23 2:21 PM.
    

#import <UIKit/UIKit.h>
#import "SHOperationItem.h"

NS_ASSUME_NONNULL_BEGIN

@class SHOperationView;
@protocol SHOperationViewDelegate <NSObject>

- (void)clickedActionWithOperationView:(SHOperationView *)operationView;

@end

@interface SHOperationView : UIView

@property (nonatomic, strong) SHOperationItem *item;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, strong) UIImage *icon;

@property (nonatomic, weak) id<SHOperationViewDelegate> delegate;

+ (instancetype)operationView;

@end

NS_ASSUME_NONNULL_END
