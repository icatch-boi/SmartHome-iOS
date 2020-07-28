// SHFilesViewModel.h

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
    

#import <Foundation/Foundation.h>
#import "SHS3FileInfo.h"
#import "SHOperationItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface SHFilesViewModel : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<SHS3FileInfo *> *selectedFiles;
@property (nonatomic, strong, readonly) NSArray<SHOperationItem *> *operationItems;

- (void)listFilesWithDeviceID:(NSString *)deviceID date:(NSDate *)date pullup:(BOOL)pullup completion:(void (^)(NSArray<SHS3FileInfo *> * _Nullable filesInfo))completion;
- (void)clearInnerCacheData;

+ (CGFloat)filesCellRowHeight;

- (void)addSelectedFile:(SHS3FileInfo *)fileInfo;
- (void)addSelectedFiles:(NSArray<SHS3FileInfo *> *)filesInfo;
- (void)removeSelectedFilesInArray:(NSArray<SHS3FileInfo *> *)filesInfo;
- (void)clearSelectedFiles;

- (void)deleteSelectFileWithCompletion:(void (^)(NSArray<SHS3FileInfo *> *deleteSuccess, NSArray<SHS3FileInfo *> *deleteFailed))completion;

- (void)downloadHandleWithDeviceID:(NSString *)deviceID;

@end

NS_ASSUME_NONNULL_END
