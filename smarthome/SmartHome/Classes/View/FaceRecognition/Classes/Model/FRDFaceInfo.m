//
//  FRDFaceInfo.m
//  FaceRecognition
//
//  Created by ZJ on 2018/9/13.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "FRDFaceInfo.h"

@interface FRDFaceInfo ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;

@end

@implementation FRDFaceInfo

+ (instancetype)faceInfoWithDict:(NSDictionary *)dict {
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

@end
