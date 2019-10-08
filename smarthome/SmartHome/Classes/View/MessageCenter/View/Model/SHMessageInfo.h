// SHMessage.h

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
 
 // Created by zj on 2019/7/26 4:50 PM.
    

#import <Foundation/Foundation.h>
#import "SHMessage.h"
#import "SHMessageFile.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^MessageInfoGetMessageFileCompletion)(UIImage * _Nullable image);

@interface SHMessageInfo : NSObject

@property (nonatomic, copy, readonly) NSString *msg;
@property (nonatomic, copy, readonly) NSString *time;
@property (nonatomic, strong, readonly) SHMessage *message;
@property (nonatomic, strong) NSString *deviceID;
@property (nonatomic, strong, readonly) SHMessageFile *messageFile;
@property (nonatomic, copy, readonly) NSString *fileIdentifier;
@property (nonatomic, copy, readonly) NSString *localTimeString;

+ (instancetype)messageInfoWithDict:(NSDictionary *)dict;
+ (instancetype)messageInfoWithDeviceID:(NSString *)deviceID messageDict:(NSDictionary *)messageDict;

- (void)getMessageFileWithCompletion:(nullable MessageInfoGetMessageFileCompletion)completion;

@end

NS_ASSUME_NONNULL_END
