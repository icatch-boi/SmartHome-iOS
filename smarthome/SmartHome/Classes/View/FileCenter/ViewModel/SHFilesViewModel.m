// SHFilesViewModel.m

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
 
 // Created by zj on 2019/10/17 7:57 PM.
    

#import "SHFilesViewModel.h"
#import "SHENetworkManagerCommon.h"

static const CGFloat kTopSpace = 8;
static const CGFloat kIconWithScreenWidthScale = 0.45;
static const CGFloat kIconWidthWithHeightScale = 16.0 / 9;

@implementation SHFilesViewModel

- (void)listFilesWithDeviceID:(NSString *)deviceID date:(NSDate *)date completion:(void (^)(NSArray<SHS3FileInfo *> * _Nullable filesInfo))completion {
    [[SHENetworkManager sharedManager] listFilesWithDeviceID:deviceID queryDate:date startKey:nil number:0 completion:^(NSArray<SHS3FileInfo *> * _Nullable filesInfo) {
        
        if (completion) {
            completion(filesInfo);
        }
    }];
}

+ (CGFloat)filesCellRowHeight {
    CGFloat screenW = [[UIScreen mainScreen] bounds].size.width;
    NSInteger space = kTopSpace;
    
    CGFloat imgViewW = screenW  * kIconWithScreenWidthScale;
    CGFloat imgViewH = imgViewW / kIconWidthWithHeightScale;
    
    CGFloat rowH = imgViewH + space * 2;
    
    return rowH;
}

@end
