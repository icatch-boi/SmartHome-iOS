//
//  ZJRequestError.m
//  FaceDetectionDemo-OC
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "ZJRequestError.h"

@interface ZJRequestError ()

@property (nonatomic, copy) NSNumber *error_code;
@property (nonatomic, copy) NSString *error;
@property (nonatomic, copy) NSString *error_description;
@property (nonatomic, copy) NSString *name;

@end

@implementation ZJRequestError

+ (instancetype)requestErrorWithNSError:(NSError *)error {
    NSData *data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
    
    NSDictionary *dict = @{
                           @"error_description": @"Unknown Error",
                           };
    
    if (data != nil) {
        id temp = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        if (error) {
            dict = temp;
        }
    }
    
    return [self requestErrorWithDict:dict];
}

+ (instancetype)requestErrorWithDict:(NSDictionary *)dict {
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
    if ([key isEqualToString:@"error_message"]) {
        [self setValuesForKeysWithDictionary:value];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (NSString *)description {
    NSArray<NSString *> *keys = @[@"error_code",
                                  @"error",
                                  @"error_description",
                                  ];
    return [self dictionaryWithValuesForKeys:keys].description;
}

@end
