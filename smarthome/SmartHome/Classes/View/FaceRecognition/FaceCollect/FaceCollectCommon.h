// FaceCollectCommon.h

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
 
 // Created by zj on 2019/8/7 10:30 AM.
    

#ifndef FaceCollectCommon_h
#define FaceCollectCommon_h

#import <UIKit/UIKit.h>
// sensor 0237: 716*512 --> 224*224
// sensor 4689: 684*512 --> 224*224
static const CGFloat kImageWHScale = 684.0 / 512; //716.0 / 512;
static const CGFloat kCompressImageWidth = 224;

#import "SHUserAccount.h"

FOUNDATION_EXPORT NSString * _Nullable FaceCollectImageKey(NSString * _Nonnull userID, NSString * _Nonnull faceID);

#endif /* FaceCollectCommon_h */
