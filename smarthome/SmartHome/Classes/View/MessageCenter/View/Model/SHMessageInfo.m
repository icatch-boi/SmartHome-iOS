// SHMessage.m

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
    

#import "SHMessageInfo.h"
#import "SHNetworkManager.h"
#import "SHUserAccountCommon.h"

@interface SHMessageInfo ()

@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, strong) SHMessage *message;
@property (nonatomic, strong) SHMessageFile *messageFile;

@end

@implementation SHMessageInfo

+ (instancetype)messageInfoWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"msg"]) {
        id json = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        
       _message = [SHMessage messageWithDict:json];
    }

    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (void)getMessageFileWithCompletion:(nullable MessageInfoGetMessageFileCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_messageFile != nil) {
            [self downloadMessageFileWithCompletion:completion];
        } else {
            [SHMessageFile getMessageFileWithDeviceID:_deviceID fileName:[self createFileName] completion:^(SHMessageFile * _Nullable messageFile) {
                if (messageFile != nil) {
                    _messageFile = messageFile;
                    [self downloadMessageFileWithCompletion:completion];
                } else {
                    if (completion) {
                        completion(nil);
                    }
                }
            }];
        }
    });
}

- (void)downloadMessageFileWithCompletion:(nullable MessageInfoGetMessageFileCompletion)completion {
    if (_messageFile.messageImage != nil) {
        if (completion) {
            completion(_messageFile.messageImage);
        }
    } else {
        [[SHNetworkManager sharedNetworkManager] downloadFileWithURLString:_messageFile.url finished:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"download Message file is success: %d", isSuccess);
            
            UIImage *image;
            
            if (isSuccess) {
                image = [[UIImage alloc] initWithData:result];
                
                if (image != nil) {
                    _messageFile.messageImage = image;
                }
            }
            
            if (completion) {
                completion(image);
            }
        }];
    }
}

- (NSString *)createFileName {
    NSString *fileName;
    if (_message.timeInSecs != nil) {
        fileName = [NSString stringWithFormat:@"%@.jpg", _message.timeInSecs];
    }
    
    return fileName;
}

- (NSString *)localTimeString {
    return _time != nil ? [SHUserAccountCommon dateTransformFromString:_time] : @"";
}

@end
