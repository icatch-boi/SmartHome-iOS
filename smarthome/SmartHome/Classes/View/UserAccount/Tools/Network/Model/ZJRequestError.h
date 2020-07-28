//
//  ZJRequestError.h
//  FaceDetectionDemo-OC
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    ZJRequestErrorCodeInvalidParameters = -10041,
} ZJRequestErrorCode;

@interface ZJRequestError : NSObject

@property (nonatomic, copy, readonly) NSNumber *error_code;
@property (nonatomic, copy, readonly) NSString *error;
@property (nonatomic, copy, readonly) NSString *error_description;
@property (nonatomic, copy, readonly) NSString *name;

- (instancetype)initWithDict:(NSDictionary *)dict;
+ (instancetype)requestErrorWithDict:(NSDictionary *)dict;
+ (instancetype)requestErrorWithNSError:(NSError *)error;
+ (instancetype)requestErrorWithDescription:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
