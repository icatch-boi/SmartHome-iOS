// SHFCDownloaderOp.h

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
 
 // Created by zj on 2019/10/25 6:28 PM.
    

#import <Foundation/Foundation.h>
#import "SHS3FileInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^DownloadFinishedBlock)();
@interface SHFCDownloaderOp : NSOperation

+ (instancetype)fileCenterDownloaderOpWithFileInfo:(SHS3FileInfo *)fileInfo finishedBlock:(nullable DownloadFinishedBlock)finishedBlock;

@end

NS_ASSUME_NONNULL_END