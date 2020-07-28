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
#import "ZJDataCache.h"

@interface SHMessageInfo ()

@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, strong) SHMessage *message;
@property (nonatomic, strong) SHMessageFile *messageFile;
@property (nonatomic, strong) dispatch_semaphore_t downloadSemaphore;
@property (nonatomic, copy) NSString *fileIdentifier;

@end

@implementation SHMessageInfo

+ (instancetype)messageInfoWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

+ (instancetype)messageInfoWithDeviceID:(NSString *)deviceID messageDict:(nonnull NSDictionary *)messageDict {
    SHMessageInfo *info = [SHMessageInfo new];
    
    info.deviceID = deviceID;
    info.message = [SHMessage messageWithDict:messageDict];
    
    return info;
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
        dispatch_semaphore_wait(self.downloadSemaphore, DISPATCH_TIME_FOREVER);
        
#ifndef KUSE_S3_SERVICE
#if 0
        UIImage *image = [[ZJImageCache sharedImageCache] imageFromCacheForKey:[self makeCacheKey]];
        if (image != nil) {
            if (completion) {
                completion(image);
            }
            
            dispatch_semaphore_signal(self.downloadSemaphore);
            return;
        }
        
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
                    
                    dispatch_semaphore_signal(self.downloadSemaphore);
                }
            }];
        }
#else
        if (_messageFile != nil) {
            if (completion) {
                completion(nil);
            };
            
            dispatch_semaphore_signal(self.downloadSemaphore);
        } else {
            [SHMessageFile getMessageFileWithDeviceID:_deviceID fileName:[self createFileName] completion:^(SHMessageFile * _Nullable messageFile) {
                _messageFile = messageFile;

                if (completion) {
                    completion(nil);
                }
                    
                dispatch_semaphore_signal(self.downloadSemaphore);
            }];
        }
#endif
        
#else
        WEAK_SELF(self);
        UIImage *image = [[ZJImageCache sharedImageCache] imageFromCacheForKey:[self makeCacheKey]];
        if (image != nil) {
            if (completion) {
                completion(image, weakself.fileIdentifier);
            }
            
            dispatch_semaphore_signal(self.downloadSemaphore);
            return;
        }
        
        [[SHENetworkManager sharedManager] getDeviceMessageFileWithDeviceID:_deviceID fileName:[self createFileName] completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess && result != nil) {
                [[ZJImageCache sharedImageCache] storeImage:result forKey:[self makeCacheKey] completion:nil];

                if (completion) {
                    completion(result, weakself.fileIdentifier);
                }
            } else {
                SHLogError(SHLogTagAPP, @"Get device message file failed, error: %@", result);
                if (completion) {
                    completion(nil, weakself.fileIdentifier);
                }
            }
            
            dispatch_semaphore_signal(self.downloadSemaphore);
        }];
#endif
    });
}

- (void)downloadMessageFileWithCompletion:(nullable MessageInfoGetMessageFileCompletion)completion {
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] downloadFileWithURLString:_messageFile.url finished:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"download Message file is success: %d", isSuccess);
        
        UIImage *image;
        
        if (isSuccess) {
            image = [[UIImage alloc] initWithData:result];
            
            if (image != nil) {
                [[ZJImageCache sharedImageCache] storeImage:image forKey:[self makeCacheKey] completion:nil];
            }
        }
        
        if (completion) {
            completion(image, weakself.messageFile.url);
        }
        
        dispatch_semaphore_signal(self.downloadSemaphore);
    }];
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

- (NSString *)makeCacheKey {
    return _deviceID ? [NSString stringWithFormat:@"%@_%@", _deviceID, [self createFileName]] : nil;
}

- (dispatch_semaphore_t)downloadSemaphore {
    if (_downloadSemaphore == nil) {
        _downloadSemaphore = dispatch_semaphore_create(1);
    }
    
    return _downloadSemaphore;
}

- (NSString *)fileIdentifier {
    if (_fileIdentifier == nil) {
        _fileIdentifier = [self makeCacheKey];
    }
    
    return _fileIdentifier;
}

#pragma mark - Draw HumanoidBox
- (void)drawHumanoidBoxWithOriginImage:(UIImage *)image toView:(UIView *)view {
    __block UIView *box = nil;
    
    [self.message.locationInfos enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.count != 0) {
            CGRect rect = [self convertRectWithLocationInfo:obj originImage:image toView:view];
            SHLogInfo(SHLogTagAPP, @"Humanoid rect: %@", NSStringFromCGRect(rect));

            CALayer *layer = [self createBoxLayer];
            layer.frame = rect;
            
//            [self adjustHumanoidBoxWithLocationInfo:obj layer:layer toView:view];

            box = box ? box : [self createBoxView];
            
            [box.layer addSublayer:layer];
        }
    }];
    
    box != nil ? [view addSubview:box] : void();
}

- (void)adjustHumanoidBoxWithLocationInfo:(NSDictionary *)obj layer:(CALayer *)layer toView:(UIView *)view {
    int confidence = [obj[@"confidence"] intValue];
    
    if (confidence > 0 && confidence < 80) {
        float widthratio = 1.1f;
        float heightratio = 1.2f;
        
        layer.transform = CATransform3DIdentity;

        if (confidence <= 75) {
            heightratio = 1.3f;
        }
        
        layer.transform = CATransform3DMakeScale(widthratio, heightratio, 1.0);
        
        CGRect newRect = layer.frame;
        
        SHLogInfo(SHLogTagAPP, @"Before rect: %@", NSStringFromCGRect(newRect));

        CGFloat x = MAX(0, CGRectGetMinX(newRect));
        CGFloat y = MAX(0, CGRectGetMinY(newRect));
        CGFloat maxX = MIN(CGRectGetWidth(view.frame), CGRectGetMaxX(newRect));
        CGFloat maxY = MIN(CGRectGetHeight(view.frame), CGRectGetMaxY(newRect));
        
        newRect = CGRectMake(x, y, maxX - x, maxY - y);
        
        SHLogInfo(SHLogTagAPP, @"After rect: %@", NSStringFromCGRect(newRect));
        layer.frame = newRect;
    }
}

- (CGRect)convertRectWithLocationInfo:(NSDictionary *)obj originImage:(UIImage *)image toView:(UIView *)view {
    CGFloat x = [obj[@"left"] floatValue];
    CGFloat y = [obj[@"top"] floatValue];
    CGFloat width = [obj[@"width"] floatValue];
    CGFloat height = [obj[@"height"] floatValue];
    
    CGFloat widthScale = image.size.width / CGRectGetWidth(view.bounds);
    CGFloat heightScale = image.size.height / CGRectGetHeight(view.bounds);
    
    x = x / widthScale;
    y = y / heightScale;
    width = width / widthScale;
    height = height / heightScale;
    
    return CGRectMake(x, y, width, height);
}

#pragma mark - HumanoidBox
- (CALayer *)createBoxLayer {
    CALayer *layer = [[CALayer alloc] init];
    
    layer.borderColor = [UIColor greenColor].CGColor;
    layer.borderWidth = 1;
    
    return layer;
}

- (UIView *)createBoxView {
    UIView *box = [[UIView alloc] init];
    box.tag = kHumanoidBoxViewTag;
    
    return box;
}

@end
