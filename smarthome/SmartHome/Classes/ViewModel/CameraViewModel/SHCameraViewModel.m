// SHCameraViewModel.m

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
 
 // Created by zj on 2018/3/21 下午2:50.
    

#import "SHCameraViewModel.h"

static const CGFloat kCameraTitleHeight = 10;
static const CGFloat kSpace = 10;

@interface SHCameraViewModel ()

@property (nonatomic, strong) SHCameraObject *cameraObj;

@end

@implementation SHCameraViewModel

- (instancetype)initWithCameraObject:(SHCameraObject *)cameraObj
{
    self = [super init];
    if (self) {
        self.cameraObj = cameraObj;
//        [self calaRowHeight];
    }
    return self;
}

- (void)calaRowHeight {
    CGFloat width = MIN(UIScreen.screenWidth, UIScreen.screenHeight);
    CGFloat imageViewHeight = (width/*UIScreen.screenWidth*/ /*- 2 * kSpace*/) * 9 / 16;
    CGFloat footbarHeight = width/*UIScreen.screenWidth*/ * 27 / 160;
    _rowHeight = kCameraTitleHeight + imageViewHeight + footbarHeight + kSpace + 1;
}

+ (CGFloat)rowHeight {
    CGFloat width = MIN(UIScreen.screenWidth, UIScreen.screenHeight);
    CGFloat imageViewHeight = (width/*UIScreen.screenWidth*/ /*- 2 * kSpace*/) * 9 / 16;
    CGFloat footbarHeight = width/*UIScreen.screenWidth*/ * 27 / 160;
    CGFloat height = kCameraTitleHeight + imageViewHeight + footbarHeight + kSpace + 1;
    
    SHLogInfo(SHLogTagAPP, @"current row height: %f", height);
    return height;
}

@end
