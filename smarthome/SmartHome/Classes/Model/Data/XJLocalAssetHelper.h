// XJLocalAssetHelper.h

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
 
 // Created by zj on 2018/6/8 下午4:36.
    

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface XJLocalAssetHelper : NSObject

+ (instancetype)sharedLocalAssetHelper;
//+ (instancetype)allocWithZone:(struct _NSZone *)zone;

- (BOOL)addNewAssetToLocalAlbum:(ICatchFile)file forKey:(NSString *)key;
- (BOOL)addNewAssetWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName andFileType:(ICatchFileType)fileType forKey:(NSString *)key;
- (void)deleteLocalAsset:(NSString *)localIdentifier forKey:(NSString *)key completionHandler:(nullable void(^)(BOOL success))completionHandler;

- (NSArray *)readFromPlist;

@end
NS_ASSUME_NONNULL_END
